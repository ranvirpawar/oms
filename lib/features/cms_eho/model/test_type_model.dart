// lib/features/team_lead/performance_dashboard/model/test_type_model.dart

class TestTypeModel {
  final String labName;
  final int labCode;
  final int biochemistry;
  final int clinicalPathology;
  final int hematology;
  final int immunoassay;
  final int serology;
  final int microbiology;
  final int pathology;
  final int specialTests;

  TestTypeModel({
    required this.labName,
    required this.labCode,
    required this.biochemistry,
    required this.clinicalPathology,
    required this.hematology,
    required this.immunoassay,
    required this.serology,
    required this.microbiology,
    required this.pathology,
    required this.specialTests,
  });

  factory TestTypeModel.fromJson(Map<String, dynamic> json) {
    return TestTypeModel(
      labName: json['LabName'] ?? '',
      labCode: json['labcode'] ?? 0,
      biochemistry: json['Biochemistry'] ?? 0,
      clinicalPathology: json['Clinical Pathology'] ?? 0,
      hematology: json['Hematology'] ?? 0,
      immunoassay: json['Immunoassay'] ?? 0,
      serology: json['Serology'] ?? 0,
      microbiology: json['Microbiology'] ?? 0,
      pathology: json['Pathology'] ?? 0,
      specialTests: json['Special Tests'] ?? 0,
    );
  }

  // Calculate total tests
  int get totalTests =>
      biochemistry +
          clinicalPathology +
          hematology +
          immunoassay +
          serology +
          microbiology +
          pathology +
          specialTests;

  // Get all test categories as a map
  Map<String, int> get testCategories => {
    'Biochemistry': biochemistry,
    'Clinical Pathology': clinicalPathology,
    'Hematology': hematology,
    'Immunoassay': immunoassay,
    'Serology': serology,
    'Microbiology': microbiology,
    'Pathology': pathology,
    'Special Tests': specialTests,
  };
}