/// Data model representing a carbon footprint activity
class Activity {
  int? id; // Primary key for database
  String type; // e.g., 'Transport', 'Food', 'Home Energy'
  String subtype; // e.g., 'Car Trip', 'Vegan Meal', 'Electricity Use'
  double value; // User-inputted metric (km, kg, kWh, etc.)
  double carbonFootprint; // Calculated CO2 equivalent in kg
  DateTime date; // Date of the activity

  Activity({
    this.id,
    required this.type,
    required this.subtype,
    required this.value,
    required this.carbonFootprint,
    required this.date,
  });

  /// Convert Activity to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'subtype': subtype,
      'value': value,
      'carbonFootprint': carbonFootprint,
      'date': date.millisecondsSinceEpoch,
    };
  }

  /// Create Activity from Map (from database)
  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'],
      type: map['type'],
      subtype: map['subtype'],
      value: map['value'],
      carbonFootprint: map['carbonFootprint'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
    );
  }

  /// Create a copy of this Activity with optional changes
  Activity copyWith({
    int? id,
    String? type,
    String? subtype,
    double? value,
    double? carbonFootprint,
    DateTime? date,
  }) {
    return Activity(
      id: id ?? this.id,
      type: type ?? this.type,
      subtype: subtype ?? this.subtype,
      value: value ?? this.value,
      carbonFootprint: carbonFootprint ?? this.carbonFootprint,
      date: date ?? this.date,
    );
  }

  @override
  String toString() {
    return 'Activity{id: $id, type: $type, subtype: $subtype, value: $value, carbonFootprint: $carbonFootprint, date: $date}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Activity &&
        other.id == id &&
        other.type == type &&
        other.subtype == subtype &&
        other.value == value &&
        other.carbonFootprint == carbonFootprint &&
        other.date == date;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        type.hashCode ^
        subtype.hashCode ^
        value.hashCode ^
        carbonFootprint.hashCode ^
        date.hashCode;
  }
} 