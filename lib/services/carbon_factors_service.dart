import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/carbon_factor.dart';

/// Service class for loading and managing carbon emission factors
class CarbonFactorsService {
  static const String _assetPath = 'assets/data/carbon_factors.json';
  
  // Singleton pattern
  static final CarbonFactorsService _instance = CarbonFactorsService._internal();
  factory CarbonFactorsService() => _instance;
  CarbonFactorsService._internal();

  List<CarbonFactor>? _carbonFactors;
  Map<String, List<CarbonFactor>>? _factorsByType;

  /// Load carbon factors from assets
  Future<void> loadCarbonFactors() async {
    if (_carbonFactors != null) return; // Already loaded

    try {
      final String jsonString = await rootBundle.loadString(_assetPath);
      final List<dynamic> jsonList = json.decode(jsonString);
      
      _carbonFactors = jsonList
          .map((json) => CarbonFactor.fromJson(json))
          .toList();
          
      // Group factors by type for faster access
      _factorsByType = <String, List<CarbonFactor>>{};
      for (var factor in _carbonFactors!) {
        if (_factorsByType![factor.type] == null) {
          _factorsByType![factor.type] = [];
        }
        _factorsByType![factor.type]!.add(factor);
      }
    } catch (e) {
      throw Exception('Failed to load carbon factors: $e');
    }
  }

  /// Get all carbon factors
  List<CarbonFactor> getAllFactors() {
    if (_carbonFactors == null) {
      throw Exception('Carbon factors not loaded. Call loadCarbonFactors() first.');
    }
    return _carbonFactors!;
  }

  /// Get all available activity types
  List<String> getAvailableTypes() {
    if (_factorsByType == null) {
      throw Exception('Carbon factors not loaded. Call loadCarbonFactors() first.');
    }
    return _factorsByType!.keys.toList()..sort();
  }

  /// Get subtypes for a specific activity type
  List<String> getSubtypesForType(String type) {
    if (_factorsByType == null) {
      throw Exception('Carbon factors not loaded. Call loadCarbonFactors() first.');
    }
    
    final factors = _factorsByType![type];
    if (factors == null) return [];
    
    return factors.map((f) => f.subtype).toList()..sort();
  }

  /// Get carbon factor for a specific type and subtype
  CarbonFactor? getFactorForActivity(String type, String subtype) {
    if (_factorsByType == null) {
      throw Exception('Carbon factors not loaded. Call loadCarbonFactors() first.');
    }
    
    final factors = _factorsByType![type];
    if (factors == null) return null;
    
    try {
      return factors.firstWhere(
        (factor) => factor.subtype == subtype,
      );
    } catch (e) {
      return null; // Not found
    }
  }

  /// Calculate carbon footprint for given activity parameters
  double calculateCarbonFootprint(String type, String subtype, double value) {
    final factor = getFactorForActivity(type, subtype);
    if (factor == null) return 0.0;
    
    return factor.factor * value;
  }

  /// Get the unit string for a specific activity
  String? getUnitForActivity(String type, String subtype) {
    final factor = getFactorForActivity(type, subtype);
    return factor?.unit;
  }

  /// Check if carbon factors are loaded
  bool get isLoaded => _carbonFactors != null;

  /// Clear loaded data (useful for testing)
  void clear() {
    _carbonFactors = null;
    _factorsByType = null;
  }
} 