class RejectedTests {
  final String visitDate;
  final int visitCode;
  final String orderId;
  final int labCode;
  final String labName;
  final String fullName;
  final String gender;
  final int age;
  final String ageTitle;
  final String mobile;
  final int serviceCode;
  final String serviceName;
  final int facilityCode;
  final String facilityName;
  final String reason;
  final String rejectionDate;
  final int rejectedTestsCount;

  RejectedTests({
    required this.visitDate,
    required this.visitCode,
    required this.orderId,
    required this.labCode,
    required this.labName,
    required this.fullName,
    required this.gender,
    required this.age,
    required this.ageTitle,
    required this.mobile,
    required this.serviceCode,
    required this.serviceName,
    required this.facilityCode,
    required this.facilityName,
    required this.reason,
    required this.rejectionDate,
    required this.rejectedTestsCount,
  });

  factory RejectedTests.fromJson(Map<String, dynamic> json) {
    return RejectedTests(
      visitDate:  json['VisitDate'] ?? '',
      visitCode: json['VisitCode'] ?? 0,
      orderId: json['OrderID'] ?? '',
      labCode: json['LabCode'] ?? 0,
      labName: json['LabName'] ?? '',
      fullName: json['FullName'] ?? '',
      gender: json['Gender'] ?? '',
      age: json['Age'] ?? 0,
      ageTitle: json['AgeTitle'] ?? '',
      mobile: json['Mobile'] ?? '',
      serviceCode: json['ServiceCode'] ?? 0,
      serviceName: json['ServiceName'] ?? '',
      facilityCode: json['FacilityCode'] ?? 0,
      facilityName: json['FacilityName'] ?? '',
      reason: json['Reason'] ?? '',
      rejectionDate: json['RejectionDate'] ?? '',
      rejectedTestsCount: json['RejectedTestsCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'VisitDate': visitDate,
      'VisitCode': visitCode,
      'OrderID': orderId,
      'LabCode': labCode,
      'LabName': labName,
      'FullName': fullName,
      'Gender': gender,
      'Age': age,
      'AgeTitle': ageTitle,
      'Mobile': mobile,
      'ServiceCode': serviceCode,
      'ServiceName': serviceName,
      'FacilityCode': facilityCode,
      'FacilityName': facilityName,
      'Reason': reason,
      'RejectionDate': rejectionDate,
      'RejectedTestsCount': rejectedTestsCount,
    };
  }
}
