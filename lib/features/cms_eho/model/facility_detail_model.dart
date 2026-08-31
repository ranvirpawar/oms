// facility_detail_model.dart

class FacilityDetailModel {
  final String facilityName;
  final int mobCatCode;
  final String catName;
  final int yearlyTarget;
  final int patCount;
  final int diff;
  final String ward;
  const FacilityDetailModel({
    required this.facilityName,
    required this.mobCatCode,
    required this.catName,
    required this.yearlyTarget,
    required this.patCount,
    required this.diff,
    required this.ward
  });

  factory FacilityDetailModel.fromJson(Map<String, dynamic> json) {
    return FacilityDetailModel(
      facilityName: (json['FType'] ?? json['Ftype']) as String? ?? '',
      mobCatCode: (json['MOBCATCODE'] as num?)?.toInt() ?? 0,
      catName: json['CatName'] as String? ?? '',
      yearlyTarget: (json['Yearly_Target'] as num?)?.toInt() ?? 0,
      patCount: (json['Patcount'] as num?)?.toInt() ?? 0,
      diff: (json['Diff'] as num?)?.toInt() ?? 0,
      ward: (json['ward'] as String? ?? '').trim(),
    );
  }

  double get completionPercent {
    if (yearlyTarget <= 0) return 0;
    return (patCount / yearlyTarget * 100).clamp(0.0, 100.0);
  }
}


// ── Project Financial Year model ──────────────────────────────────────────────
class ProjectFinancialYear {
  final int yearId;
  final String yearDescription;

  const ProjectFinancialYear({
    required this.yearId,
    required this.yearDescription,
  });

  factory ProjectFinancialYear.fromJson(Map<String, dynamic> json) {
    return ProjectFinancialYear(
      yearId: (json['YearID'] as num).toInt(),
      yearDescription: json['YearDiscription'] as String,
    );
  }
}
