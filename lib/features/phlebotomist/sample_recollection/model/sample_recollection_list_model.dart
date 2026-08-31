class SampleRecollectionList {
  final int visitCode;
  final String orderId;
  final String reason;
  final String fullName;
  final String gender;
  final int age;
  final String ageTitle;
  final int rejectedTestsCount;
  final String rejectedTestsName;

  SampleRecollectionList({
    required this.visitCode,
    required this.orderId,
    required this.reason,
    required this.fullName,
    required this.gender,
    required this.age,
    required this.ageTitle,
    required this.rejectedTestsCount,
    required this.rejectedTestsName,
  });

  factory SampleRecollectionList.fromJson(Map<String, dynamic> json) {
    return SampleRecollectionList(
      visitCode: json['VisitCode'] ?? 0,
      orderId: json['OrderID'] ?? '',
      reason: json['Reason'] ?? '',
      fullName: json['FullName'] ?? '',
      gender: json['Gender'] ?? '',
      age: json['Age'] ?? 0,
      ageTitle: json['AgeTitle'] ?? '',
      rejectedTestsCount: json['RejectedTestsCount'] ?? 0,
      rejectedTestsName: json['RejectedTestsName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'VisitCode': visitCode,
      'OrderID': orderId,
      'Reason': reason,
      'FullName': fullName,
      'Gender': gender,
      'Age': age,
      'AgeTitle': ageTitle,
      'RejectedTestsCount': rejectedTestsCount,
      'RejectedTestsName': rejectedTestsName,
    };
  }
}
