// models/test_model.dart
class TestModel {
  final int? headingId;
  final String? heading;
  final String? headingCode;
  final String? labcategory;
  final int? testId;
  final String? testName;
  final double? testRate;
  final String? testCode;
  final int? srno;
  final String? isCompaerSoloubility;
  final int? tubeId;
  final String? tubeContent;
  final String? dh;
  final String? phc;
  final String? rh;
   int? testCategoryCode;
  final Map<String, dynamic>? hmisData;
  TestModel({
    this.headingId,
    this.heading,
    this.headingCode,
    this.labcategory,
    this.testId,
    this.testName,
    this.testRate,
    this.testCode,
    this.srno,
    this.isCompaerSoloubility,
    this.tubeId,
    this.tubeContent,
    this.dh,
    this.phc,
    this.rh,
    this.testCategoryCode,
    this.hmisData,
  });

  factory TestModel.fromJson(Map<String, dynamic> json) {
    return TestModel(
      headingId: json['headingId'] as int?,
      heading: json['heading'] as String?,
      headingCode: json['headingCode'] as String?,
      labcategory: json['Labcategory'] as String?,
      testId: json['testId'] as int?,
      testName: json['testName'] as String?,
      testRate: (json['testRate'] as num?)?.toDouble(),
      testCode: json['testCode'] as String?,
      srno: json['SRNO'] as int?,
      isCompaerSoloubility: json['ISCompaerSoloubility'] as String?,
      tubeId: json['TubeId'] as int?,
      tubeContent: json['TubeContent'] as String?,
      dh: json['DH'] as String?,
      phc: json['PHC'] as String?,
      rh: json['RH'] as String?,
      testCategoryCode: json['testCategoryCode'] as int?,
      hmisData: json['hmisData'],
    );
  }



  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestModel && other.testId == testId;
  }

  @override
  int get hashCode => testId.hashCode;
}

/*
// Selected Test Model for API submission
class SelectedTestModel {
  final int testId;
  final String testName;
  final double testRate;
  final String testCode;
  final String tubeContent;
  final int tubeId;
  final String heading;
  final int headingId;
  final String headingCode;
  final String? isCompaerSoloubility;
  final String? dh;
  final String? phc;
  final String? rh;
  final int? srno;
  final String labcategory;

  SelectedTestModel({
    required this.testId,
    required this.testName,
    required this.testRate,
    required this.testCode,
    required this.tubeContent,
    required this.tubeId,
    required this.heading,
    required this.headingId,
    required this.headingCode,
    this.isCompaerSoloubility,
    this.dh,
    this.phc,
    this.rh,
    this.srno,
    required this.labcategory,
  });

  factory SelectedTestModel.fromTestModel(TestModel test) {
    return SelectedTestModel(
      testId: test.testId!,
      testName: test.testName!,
      testRate: test.testRate!,
      testCode: test.testCode!,
      tubeContent: test.tubeContent!,
      tubeId: test.tubeId!,
      heading: test.heading!,
      headingId: test.headingId!,
      headingCode: test.headingCode!,
      isCompaerSoloubility: test.isCompaerSoloubility,
      dh: test.dh,
      phc: test.phc,
      rh: test.rh,
      srno: test.srno,
      labcategory: test.labcategory!,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'testId': testId,
      'testName': testName,
      'testRate': testRate,
      'testCode': testCode,
      'TubeContent': tubeContent,
      'TubeId': tubeId,
      'heading': heading,
      'headingId': headingId,
      'headingCode': headingCode,
      'ISCompaerSoloubility': isCompaerSoloubility,
      'DH': dh,
      'PHC': phc,
      'RH': rh,
      'SRNO': srno,
      'Labcategory': labcategory,
    };
  }
}*/
