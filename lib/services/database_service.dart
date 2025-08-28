import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import '../models/activity.dart';

/// Service class for managing database operations using sqflite
class DatabaseService {
  static const String _databaseName = 'carbon_footprint.db'; // pathless name; on Web it becomes an IndexedDB store
  static const int _databaseVersion = 1;
  static const String _tableName = 'activities';

  // Singleton pattern
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;
  static bool _initialized = false;

  /// Initialize the database service
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Initialize database factory depending on platform
      if (kIsWeb) {
        // Web: avoid web worker requirement by using the no-worker factory
        databaseFactory = databaseFactoryFfiWebNoWebWorker;
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Desktop native (FFI)
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      
      // Touch database path on non-web just to ensure availability
      if (!kIsWeb) {
        await getDatabasesPath();
      }
      
      _initialized = true;
    } catch (e) {
      // Log error but continue - don't block app startup
      debugPrint('Database initialization error: $e');
      _initialized = true;
    }
  }

  /// Get database instance, create if doesn't exist
  Future<Database> get database async {
    await initialize();
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize the database and create tables
  Future<Database> _initDatabase() async {
    try {
      // On Web, use the database name directly (no filesystem paths)
      final dbPath = kIsWeb ? _databaseName : join(await getDatabasesPath(), _databaseName);
      
      return await openDatabase(
        dbPath,
        version: _databaseVersion,
        onCreate: _onCreate,
      );
    } catch (e) {
      debugPrint('Error initializing database: $e');
      rethrow;
    }
  }

  /// Create the activities table
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        subtype TEXT NOT NULL,
        value REAL NOT NULL,
        carbonFootprint REAL NOT NULL,
        date INTEGER NOT NULL
      )
    ''');
  }

  /// Create a new activity record
  Future<int> createActivity(Activity activity) async {
    try {
      final db = await database;
      final id = await db.insert(_tableName, activity.toMap());
      return id;
    } catch (e) {
      debugPrint('Error creating activity: $e');
      rethrow;
    }
  }

  /// Read all activity records
  Future<List<Activity>> readAllActivities() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      orderBy: 'date DESC', // Most recent first
    );

    return List.generate(maps.length, (i) {
      return Activity.fromMap(maps[i]);
    });
  }

  /// Read activities within a specific date range
  Future<List<Activity>> readActivitiesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'date >= ? AND date <= ?',
      whereArgs: [
        start.millisecondsSinceEpoch,
        end.millisecondsSinceEpoch,
      ],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return Activity.fromMap(maps[i]);
    });
  }

  /// Read activities by type (e.g., 'Transport', 'Food')
  Future<List<Activity>> readActivitiesByType(String type) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'date DESC',
    );

    return List.generate(maps.length, (i) {
      return Activity.fromMap(maps[i]);
    });
  }

  /// Read a single activity by ID
  Future<Activity?> readActivityById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Activity.fromMap(maps.first);
    }
    return null;
  }

  /// Update an existing activity
  Future<int> updateActivity(Activity activity) async {
    final db = await database;
    return await db.update(
      _tableName,
      activity.toMap(),
      where: 'id = ?',
      whereArgs: [activity.id],
    );
  }

  /// Delete an activity by ID
  Future<int> deleteActivity(int id) async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete all activities
  Future<int> deleteAllActivities() async {
    final db = await database;
    return await db.delete(_tableName);
  }

  /// Get total carbon footprint for a date range
  Future<double> getTotalCarbonFootprint({
    DateTime? start,
    DateTime? end,
  }) async {
    final db = await database;
    String where = '';
    List<dynamic> whereArgs = [];

    if (start != null && end != null) {
      where = 'WHERE date >= ? AND date <= ?';
      whereArgs = [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch];
    }

    final result = await db.rawQuery('''
      SELECT SUM(carbonFootprint) as total 
      FROM $_tableName $where
    ''', whereArgs);

    return (result.first['total'] as double?) ?? 0.0;
  }

  /// Get carbon footprint by activity type for a date range
  Future<Map<String, double>> getCarbonFootprintByType({
    DateTime? start,
    DateTime? end,
  }) async {
    final db = await database;
    String where = '';
    List<dynamic> whereArgs = [];

    if (start != null && end != null) {
      where = 'WHERE date >= ? AND date <= ?';
      whereArgs = [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch];
    }

    final result = await db.rawQuery('''
      SELECT type, SUM(carbonFootprint) as total 
      FROM $_tableName $where
      GROUP BY type
    ''', whereArgs);

    Map<String, double> footprintByType = {};
    for (var row in result) {
      footprintByType[row['type'] as String] = (row['total'] as double?) ?? 0.0;
    }

    return footprintByType;
  }

  /// Get daily carbon footprint for charting
  Future<Map<DateTime, double>> getDailyCarbonFootprint({
    DateTime? start,
    DateTime? end,
  }) async {
    final db = await database;
    String where = '';
    List<dynamic> whereArgs = [];

    if (start != null && end != null) {
      where = 'WHERE date >= ? AND date <= ?';
      whereArgs = [start.millisecondsSinceEpoch, end.millisecondsSinceEpoch];
    }

    final result = await db.rawQuery('''
      SELECT date, SUM(carbonFootprint) as total 
      FROM $_tableName $where
      GROUP BY DATE(date/1000, 'unixepoch')
      ORDER BY date
    ''', whereArgs);

    Map<DateTime, double> dailyFootprint = {};
    for (var row in result) {
      DateTime date = DateTime.fromMillisecondsSinceEpoch(row['date'] as int);
      DateTime dayOnly = DateTime(date.year, date.month, date.day);
      dailyFootprint[dayOnly] = (row['total'] as double?) ?? 0.0;
    }

    return dailyFootprint;
  }

  /// Close the database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
} 