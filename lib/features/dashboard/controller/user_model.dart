class UserModel {
  final String empCode;
  final String name;
  final String username;
  final String designation;
  final String orgName;
  final String subOrgName;
  final String centerId;
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

  /// Create UserModel from API map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      empCode: map['EmpCode']?.toString() ?? '',
      name: map['name'] ?? '',
      username: map['USERNAME'] ?? '',
      designation: map['Designation'] ?? '',
      orgName: map['OrgName'] ?? '',
      subOrgName: map['SubOrgName'] ?? '',
      centerId: map['CenterID']?.toString() ?? '',
      facilityName: map['FacilityName'] ?? '',
      labName: map['LabName'] ?? '',
      isActive: map['ISACTIVE'] ?? false,
    );
  }

  /// Convert back to Map (optional)
  Map<String, dynamic> toMap() {
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
