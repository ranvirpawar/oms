class PatientReportData {
  final String facilityName;
  final String patientName;
  final String mobile;
  final String barcode;
  final String visitDate;
  final int totalTestCount;
  final int reportReadyCount;
  final int reportPrintCount;
  final String reportLink;
  final String pendingPrintStatus;

  PatientReportData({
    required this.facilityName,
    required this.patientName,
    required this.mobile,
    required this.barcode,
    required this.visitDate,
    required this.totalTestCount,
    required this.reportReadyCount,
    required this.reportPrintCount,
    required this.reportLink,
    required this.pendingPrintStatus,
  });

  factory PatientReportData.fromJson(Map<String, dynamic> json) {
    return PatientReportData(
      facilityName: json['facilityname'] ?? '',
      patientName: json['PatientName'] ?? '',
      mobile: json['Mobile'] ?? '',
      barcode: json['barcode'] ?? '',
      visitDate: json['Visitdate'] ?? '',
      totalTestCount: int.tryParse(json['ToatalTesCount'] ?? '0') ?? 0,
      reportReadyCount: int.tryParse(json['ReportreadyCount'] ?? '0') ?? 0,
      reportPrintCount: int.tryParse(json['ReportPrintCount'] ?? '0') ?? 0,
      reportLink: json['ReportLink'] ?? '',
      pendingPrintStatus: json['PendingPrintStatus'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'facilityname': facilityName,
      'PatientName': patientName,
      'Mobile': mobile,
      'barcode': barcode,
      'Visitdate': visitDate,
      'ToatalTesCount': totalTestCount.toString(),
      'ReportreadyCount': reportReadyCount.toString(),
      'ReportPrintCount': reportPrintCount.toString(),
      'ReportLink': reportLink,
      'PendingPrintStatus': pendingPrintStatus,
    };
  }
}
