/// Data model representing carbon emission factors for different activities
class CarbonFactor {
  String type; // e.g., 'Transport', 'Food', 'Home Energy'
  String subtype; // e.g., 'Car Trip', 'Vegan Meal', 'Electricity Use'
  double factor; // Emission factor value
  String unit; // Unit of measurement (e.g., 'kg CO2e/km')

  CarbonFactor({
    required this.type,
    required this.subtype,
    required this.factor,
    required this.unit,
  });

  /// Create CarbonFactor from JSON Map
  factory CarbonFactor.fromJson(Map<String, dynamic> json) {
    return CarbonFactor(
      type: json['type'],
      subtype: json['subtype'],
      factor: json['factor'].toDouble(),
      unit: json['unit'],
    );
  }

  /// Convert CarbonFactor to JSON Map
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'subtype': subtype,
      'factor': factor,
      'unit': unit,
    };
  }

  @override
  String toString() {
    return 'CarbonFactor{type: $type, subtype: $subtype, factor: $factor, unit: $unit}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CarbonFactor &&
        other.type == type &&
        other.subtype == subtype &&
        other.factor == factor &&
        other.unit == unit;
  }

  @override
  int get hashCode {
    return type.hashCode ^
        subtype.hashCode ^
        factor.hashCode ^
        unit.hashCode;
  }
} 