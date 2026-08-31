class FacilityModel {
  final int centerId;
  final int facilityId;
  final String facilityName;
  final String fCategory;
  final String fType;
  final int cdacLabCode;
  final String ward;

  FacilityModel({
    required this.centerId,
    required this.facilityId,
    required this.facilityName,
    required this.fCategory,
    required this.fType,
    required this.cdacLabCode,
    required this.ward,
  });

  factory FacilityModel.fromJson(Map<String, dynamic> json) {
    return FacilityModel(
      centerId: json['centerId'],
      facilityId: json['facilityID'],
      facilityName: json['FacilityName'],
      fCategory: json['FCategory'],
      fType: json['FType'],
      cdacLabCode: json['CDACLabcode'],
      ward: json['Ward'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'centerId': centerId,
      'facilityID': facilityId,
      'FacilityName': facilityName,
      'FCategory': fCategory,
      'FType': fType,
      'CDACLabcode': cdacLabCode,
      'Ward': ward,
    };
  }
}
