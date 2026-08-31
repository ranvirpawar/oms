// models/visit_request_model.dart
class VisitRequestModel {
  final String centerId;
  final String drFirstName;
  final String drMidName;
  final String drLastName;
  final String mobileNo;
  final String photoPath;
  final String remark;
  final String latitude;
  final String longitude;
  final String userId;

  VisitRequestModel({
    required this.centerId,
    required this.drFirstName,
    required this.drMidName,
    required this.drLastName,
    required this.mobileNo,
    required this.photoPath,
    required this.remark,
    required this.latitude,
    required this.longitude,
    required this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      'CenterID': centerId,
      'DRFirstName': drFirstName,
      'DRMidName': drMidName,
      'DRLastName': drLastName,
      'MobileNo': mobileNo,
      'PhotoPath': photoPath,
      'Remark': remark,
      'Latitude': latitude,
      'Logitude': longitude, // Note: API uses 'Logitude' (typo in original)
      'USERID': userId,
    };
  }
}
