class VisitResponse {
  final String status;
  final String message;
  final List<VisitData> output;

  VisitResponse({
    required this.status,
    required this.message,
    required this.output,
  });

  factory VisitResponse.fromJson(Map<String, dynamic> json) {
    return VisitResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      output: (json['output'] as List?)
          ?.map((item) => VisitData.fromJson(item))
          .toList() ?? [],
    );
  }
}

class VisitData {
  final String distName;
  final String centerLabName;
  final String centerTypName;
  final String drFirstName;
  final String drMidName;
  final String drLastName;
  final String mobileNo;
  final String photoPath;
  final String remark;
  final double latitude;
  final double longitude;
  final String createdOn;

  VisitData({
    required this.distName,
    required this.centerLabName,
    required this.centerTypName,
    required this.drFirstName,
    required this.drMidName,
    required this.drLastName,
    required this.mobileNo,
    required this.photoPath,
    required this.remark,
    required this.latitude,
    required this.longitude,
    required this.createdOn,
  });

  factory VisitData.fromJson(Map<String, dynamic> json) {
    return VisitData(
      distName: json['DISTNAME'] ?? '',
      centerLabName: json['Center_Lab_Name'] ?? '',
      centerTypName: json['CenterTypName'] ?? '',
      drFirstName: json['DRFirstName'] ?? '',
      drMidName: json['DRMidName'] ?? '',
      drLastName: json['DRLastName'] ?? '',
      mobileNo: json['MobileNo'] ?? '',
      photoPath: json['PhotoPath'] ?? '',
      remark: json['Remark'] ?? '',
      latitude: (json['Latitude'] ?? 0.0).toDouble(),
      longitude: (json['Logitude'] ?? 0.0).toDouble(),
      createdOn: json['CreatedOn'] ?? '',
    );
  }

  String get fullName => '$drFirstName $drMidName $drLastName'.trim();
}
