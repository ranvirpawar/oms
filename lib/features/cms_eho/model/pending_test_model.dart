// lib/features/team_lead/performance_dashboard/model/pending_patient_model.dart

class PendingPatientModel {
  final int labCode;
  final String labName;
  final int cityCode;
  final String cityName;
  final int distLgdCode;
  final String distName;
  final int districtCode;
  final int pendingPatients;
  final int pendingTests;
  final int inhouseNormal;
  final int inhouseSpecial;
  final int referredNormal;
  final int referredSpecial;
  final int tyrocareNormal;
  final int tyrocareSpecial;

  PendingPatientModel({
    required this.labCode,
    required this.labName,
    required this.cityCode,
    required this.cityName,
    required this.distLgdCode,
    required this.distName,
    required this.districtCode,
    required this.pendingPatients,
    required this.pendingTests,
    required this.inhouseNormal,
    required this.inhouseSpecial,
    required this.referredNormal,
    required this.referredSpecial,
    required this.tyrocareNormal,
    required this.tyrocareSpecial,
  });

  factory PendingPatientModel.fromJson(Map<String, dynamic> json) {
    return PendingPatientModel(
      labCode: json['LabCode'] ?? 0,
      labName: json['LabName'] ?? '',
      cityCode: json['CityCode'] ?? 0,
      cityName: json['CityName'] ?? '',
      distLgdCode: json['DISTLGDCODE'] ?? 0,
      distName: json['DISTNAME'] ?? '',
      districtCode: json['DistrictCode'] ?? 0,
      pendingPatients: json['Pending_Patients'] ?? 0,
      pendingTests: json['Pending_Tests'] ?? 0,
      inhouseNormal: json['Inhouse_Normal'] ?? 0,
      inhouseSpecial: json['Inhouse_Special'] ?? 0,
      referredNormal: json['Referred_Normal'] ?? 0,
      referredSpecial: json['Referred_Special'] ?? 0,
      tyrocareNormal: json['Tyrocare_Normal'] ?? 0,
      tyrocareSpecial: json['Tyrocare_Special'] ?? 0,
    );
  }

  // Calculate total inhouse tests
  int get totalInhouse => inhouseNormal + inhouseSpecial;

  // Calculate total referred tests
  int get totalReferred => referredNormal + referredSpecial;

  // Calculate total tyrocare tests
  int get totalTyrocare => tyrocareNormal + tyrocareSpecial;

  // Calculate percentages
  double get inhousePercentage => pendingTests > 0 ? (totalInhouse / pendingTests) * 100 : 0;
  double get referredPercentage => pendingTests > 0 ? (totalReferred / pendingTests) * 100 : 0;
  double get tyrocarePercentage => pendingTests > 0 ? (totalTyrocare / pendingTests) * 100 : 0;
}