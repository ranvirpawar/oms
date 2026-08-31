// ─────────────────────────────────────────────────────────────────────────────
// consumption_model.dart
//
// What this file does:
//   • Defines the data shape for ONE row returned by GetConsuptionDashboard API.
//   • fromJson() converts the raw Map (from json.decode) into a typed object.
// ─────────────────────────────────────────────────────────────────────────────

class ConsumptionModel {
  final int fTypeId;       // facility type id  e.g. 1, 2, 3, 11
  final String fType;      // facility type name e.g. "Dispensary"
  final int mobCatCode;    // category code  1 / 2 / 3
  final String catName;    // category name  "Basic A" / "Basic B" / "Advance"
  final int yearlyTarget;  // target set for the year
  final int patCount;      // patients actually served
  final int diff;          // yearlyTarget - patCount  (can be negative)

  const ConsumptionModel({
    required this.fTypeId,
    required this.fType,
    required this.mobCatCode,
    required this.catName,
    required this.yearlyTarget,
    required this.patCount,
    required this.diff,
  });

  // Converts the JSON map from the API response into a ConsumptionModel object.
  factory ConsumptionModel.fromJson(Map<String, dynamic> json) {
    return ConsumptionModel(
      fTypeId: json['FTypeID'] as int,
      fType: json['FType'] as String,
      mobCatCode: json['MOBCATCODE'] as int,
      catName: json['CatName'] as String,
      yearlyTarget: json['Yearly_Target'] as int,
      patCount: json['Patcount'] as int,
      diff: json['Diff'] as int,
    );
  }

  // Completion percentage (0.0 – 1.0). Capped at 1 so bar never overflows.
  double get completionRatio {
    if (yearlyTarget <= 0) return patCount > 0 ? 1.0 : 0.0;
    return (patCount / yearlyTarget).clamp(0.0, 1.0);
  }

  double get completionPercent => completionRatio * 100;
}
