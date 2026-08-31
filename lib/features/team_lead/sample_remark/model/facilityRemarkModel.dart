

class FacilityRemarkModel {
  final int centerId;
  final int labcode;
  final int facilityCode;
  final String facilityName;
  final int count;
  final String remarByPhlebO;
  final int? remarIdPhlebO;
  final String remarkByLBM;
  final int? remarkByLBMID;
  final int? remarkByDCID;
  final String remarkByDC;
  final String date;
  final String dbSource;

  FacilityRemarkModel({
    required this.centerId,
    required this.labcode,
    required this.facilityCode,
    required this.facilityName,
    required this.count,
    required this.remarByPhlebO,
    required this.remarIdPhlebO,
    required this.remarkByLBM,
    required this.remarkByLBMID,
    required this.remarkByDCID,
    required this.remarkByDC,
    required this.date,
    required this.dbSource,
  });

  factory FacilityRemarkModel.fromJson(Map<String, dynamic> json) {
    return FacilityRemarkModel(
      centerId: json['CenterID'] ?? 0,
      labcode: json['Labcode'] ?? 0,
      facilityCode: json['FacilityCode'] ?? 0,
      facilityName: json['FacilityName'] ?? '',
      count: json['Count'] ?? 0,
      remarByPhlebO: json['RemarByPhlebO'] ?? '',
      remarIdPhlebO: json['RemarIdPhlebO'],
      remarkByLBM: json['RemarkByLBM'] ?? '',
      remarkByLBMID: json['RemarkByLBMID'],
      remarkByDCID: json['RemarkByDCID'],
      remarkByDC: json['RemarkByDC'] ?? '',
      date: json['Date'] ?? '',
      dbSource: json['DB_SOURCE'] ?? '',
    );
  }
}