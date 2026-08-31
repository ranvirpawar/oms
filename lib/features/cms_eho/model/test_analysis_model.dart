// lib/features/team_lead/test_analysis/model/test_analysis_model.dart

class TestAnalysisModel {
  final int srNo;
  final String summaryType;
  final int totalTests;
  final int tatMetTests;
  final int tatFailTests;
  final int normalTest;
  final int specialTest;

  TestAnalysisModel({
    required this.srNo,
    required this.summaryType,
    required this.totalTests,
    required this.tatMetTests,
    required this.tatFailTests,
    required this.normalTest,
    required this.specialTest,
  });

  factory TestAnalysisModel.fromJson(Map<String, dynamic> json) {
    return TestAnalysisModel(
      srNo: json['SrNo'] ?? 0,
      summaryType: json['SummaryType'] ?? '',
      totalTests: json['TOTAL_TESTS'] ?? 0,
      tatMetTests: json['TATMET_TESTS'] ?? 0,
      tatFailTests: json['TATFAIL_TESTS'] ?? 0,
      normalTest: json['NORMALTEST'] ?? 0,
      specialTest: json['SPECIALTEST'] ?? 0,
    );
  }

  // Calculate percentages
  double get tatMetPercentage => totalTests > 0 ? (tatMetTests / totalTests) * 100 : 0;
  double get tatFailPercentage => totalTests > 0 ? (tatFailTests / totalTests) * 100 : 0;
  double get normalTestPercentage => totalTests > 0 ? (normalTest / totalTests) * 100 : 0;
  double get specialTestPercentage => totalTests > 0 ? (specialTest / totalTests) * 100 : 0;
  // Add these getters to your TestAnalysisModel class

// Calculate percentages for Basic and Advanced tests
  double get basicTestPercentage => totalTests > 0 ? (normalTest / totalTests) * 100 : 0;
  double get advancedTestPercentage => totalTests > 0 ? (specialTest / totalTests) * 100 : 0;

}