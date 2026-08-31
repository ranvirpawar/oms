class LoginResponseModel {
  final String status;
  final String message;
  final String? token;          // ← add this
  final UserModel? user;

  LoginResponseModel({
    required this.status,
    required this.message,
    this.token,
    this.user,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    final outputList = json['output'] as List?;
    return LoginResponseModel(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      token: json['token'] as String?,           // ← read it
      user: (outputList != null && outputList.isNotEmpty)
          ? UserModel.fromJson(outputList.first)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'token': token,                            // ← include it
      'user': user?.toJson(),
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

