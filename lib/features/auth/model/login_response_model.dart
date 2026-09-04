class LoginResponseModel {
  final String status;
  final String message;
  final String? token;
  final UserModel? user;

  // ---- added for the two-factor / OTP flow ----
  final int? userId;          // returned by /Login when requiresOtp is true;
  // required input for VerifyLoginOtp
  final String? mobileNo;     // masked mobile number, e.g. "******0273"
  final bool requiresOtp;     // true on /Login's "OTP sent" response

  LoginResponseModel({
    required this.status,
    required this.message,
    this.token,
    this.user,
    this.userId,
    this.mobileNo,
    this.requiresOtp = false,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    final outputList = json['output'] as List?;
    return LoginResponseModel(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      token: json['token'] as String?,
      user: (outputList != null && outputList.isNotEmpty)
          ? UserModel.fromJson(outputList.first)
          : null,
      userId: json['userId'] is int
          ? json['userId'] as int
          : int.tryParse(json['userId']?.toString() ?? ''),
      mobileNo: json['mobileNo'] as String?,
      requiresOtp: json['requiresOtp'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'token': token,
      'user': user?.toJson(),
      'userId': userId,
      'mobileNo': mobileNo,
      'requiresOtp': requiresOtp,
    };
  }
}

class UserModel {
  final int empCode;
  final String name;
  final String username;
  final String designation;
  final String orgName;
  final String subOrgName;
  final int centerId;
  final String facilityName;
  final String labName;
  final bool isActive;

  UserModel({
    required this.empCode,
    required this.name,
    required this.username,
    required this.designation,
    required this.orgName,
    required this.subOrgName,
    required this.centerId,
    required this.facilityName,
    required this.labName,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      empCode: json['EmpCode'],
      name: json['name'],
      username: json['USERNAME'],
      designation: json['Designation'],
      orgName: json['OrgName'],
      subOrgName: json['SubOrgName'],
      centerId: json['CenterID'],
      facilityName: json['FacilityName'],
      labName: json['LabName'],
      isActive: json['ISACTIVE'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'EmpCode': empCode,
      'name': name,
      'USERNAME': username,
      'Designation': designation,
      'OrgName': orgName,
      'SubOrgName': subOrgName,
      'CenterID': centerId,
      'FacilityName': facilityName,
      'LabName': labName,
      'ISACTIVE': isActive,
    };
  }
}

