// Replaces old BagDetail — maps to GETQRBagCount response
class QRBagCountDetail {
  final int sessionID;
  final int bagId;
  final String bagcode;
  final String? ward;
  final String? fType;
  final String? facilityName;
  final int? tubecount;
  final bool isBagClosed;

  QRBagCountDetail({
    required this.sessionID,
    required this.bagId,
    required this.bagcode,
    this.ward,
    this.fType,
    this.facilityName,
    this.tubecount,
    required this.isBagClosed,
  });

  factory QRBagCountDetail.fromJson(Map<String, dynamic> json) =>
      QRBagCountDetail(
        sessionID: json['SessionID'] ?? 0,
        bagId: json['Bagid'] ?? 0,
        bagcode: json['Bagcode'] ?? '',
        ward: json['Ward'],
        fType: json['FType'],
        facilityName: json['FacilityName'],
        tubecount: int.tryParse(json['Tubecount']?.toString() ?? ''),
        isBagClosed: json['IsBagClosed']?.toString() == '1',
      );
}