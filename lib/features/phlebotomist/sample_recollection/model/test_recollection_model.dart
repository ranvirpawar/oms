class RecollectionTestListUpdated {
  final int districtCode;
  final String ward;
  final int fTypeId;
  final String fTypeShort;
  final int facilityCode;
  final String facilityName;
  final int visitCode;
  final String visitDate;
  final String orderId;
  final String patientName;
  final String mobile;
  final String testName;
  final String gender;
  final String reasonName;
  final double rate;
  final String registrationLabName;
  final String processLabName;
  final String recollectionRequired;
  final String recollectionStatus;
  final String? recollectedDate;
  final String? recollectedBarcode;
  final String reasonOfRejection;

  RecollectionTestListUpdated({
    required this.districtCode,
    required this.ward,
    required this.fTypeId,
    required this.fTypeShort,
    required this.facilityCode,
    required this.facilityName,
    required this.visitCode,
    required this.visitDate,
    required this.orderId,
    required this.patientName,
    required this.mobile,
    required this.testName,
    required this.gender,
    required this.reasonName,
    required this.rate,
    required this.registrationLabName,
    required this.processLabName,
    required this.recollectionRequired,
    required this.recollectionStatus,
    this.recollectedDate,
    this.recollectedBarcode,
    required this.reasonOfRejection,
  });

  factory RecollectionTestListUpdated.fromJson(Map<String, dynamic> json) {
    return RecollectionTestListUpdated(
      districtCode: json['DistrictCode'] ?? 0,
      ward: json['Ward'] ?? '',
      fTypeId: json['FTypeID'] ?? 0,
      fTypeShort: json['FTypeShort'] ?? '',
      facilityCode: json['FacilityCode'] ?? 0,
      facilityName: json['FacilityName'] ?? '',
      visitCode: json['VisitCode'] ?? 0,
      visitDate: json['Visitdate'] ?? '',
      orderId: json['OrderID'] ?? '',
      patientName: json['PatientName'] ?? '',
      mobile: json['Mobile'] ?? '',
      testName: json['TestName'] ?? '',
      gender: json['GENDER'] ?? '',
      reasonName: json['ReasonName'] ?? '',
      rate: (json['Rate'] as num?)?.toDouble() ?? 0.0,
      registrationLabName: json['Registration Lab Name'] ?? '',
      processLabName: json['Process Lab Name'] ?? '',
      recollectionRequired: json['Recollection Required'] ?? '',
      recollectionStatus: json['Recollection Status'] ?? '',
      recollectedDate: json['Recollected Date'],
      recollectedBarcode: json['Recollected Barcode'],
      reasonOfRejection: json['Reason of Rejection'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'DistrictCode': districtCode,
      'Ward': ward,
      'FTypeID': fTypeId,
      'FTypeShort': fTypeShort,
      'FacilityCode': facilityCode,
      'FacilityName': facilityName,
      'VisitCode': visitCode,
      'Visitdate': visitDate,
      'OrderID': orderId,
      'PatientName': patientName,
      'Mobile': mobile,
      'TestName': testName,
      'GENDER': gender,
      'ReasonName': reasonName,
      'Rate': rate,
      'Registration Lab Name': registrationLabName,
      'Process Lab Name': processLabName,
      'Recollection Required': recollectionRequired,
      'Recollection Status': recollectionStatus,
      'Recollected Date': recollectedDate,
      'Recollected Barcode': recollectedBarcode,
      'Reason of Rejection': reasonOfRejection,
    };
  }
}
