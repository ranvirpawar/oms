// models/phlebotomist_model.dart

class PhlebotomistListResponse {
  final String status;
  final String message;
  final List<Phlebotomist>? output;

  PhlebotomistListResponse({
    required this.status,
    required this.message,
    this.output,
  });

  factory PhlebotomistListResponse.fromJson(Map<String, dynamic> json) {
    return PhlebotomistListResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      output: json['output'] != null
          ? (json['output'] as List)
          .map((item) => Phlebotomist.fromJson(item))
          .toList()
          : null,
    );
  }

  bool get isSuccess => status.toLowerCase() == 'success';
}

class Phlebotomist {
  final int userId;
  final int facilityCode;
  final String facilityName;
  final String ward;
  final String userName;
  final String fType;

  Phlebotomist({
    required this.userId,
    required this.facilityCode,
    required this.facilityName,
    required this.ward,
    required this.userName,
    required this.fType,
  });

  factory Phlebotomist.fromJson(Map<String, dynamic> json) {
    return Phlebotomist(
      userId: json['userid'] ?? 0,
      facilityCode: json['facilitycode'] ?? 0,
      facilityName: json['Facilityname'] ?? '',
      ward: json['Ward'] ?? '',
      userName: json['Username'] ?? '',
      fType: json['FType'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userid': userId,
      'facilitycode': facilityCode,
      'Facilityname': facilityName,
      'Ward': ward,
      'Username': userName,
      'FType': fType,
    };
  }
}

