class ProfileData {
  final int empCode;
  final int subOrgWiseDesgId;
  final int subOrgId;
  final String subOrgName;
  final int orgId;
  final String orgName;
  final int projectId;
  final String projectName;
  final String username;
  final String name;
  final String firstName;
  final String middleName;
  final String lastName;
  final String spouseName;
  final int children;
  final String motherName;
  final String fatherName;
  final String voterId;
  final String perEmail;
  final String perMobile;
  final String pAddress;
  final String cAddress;
  final String dob;
  final String gender;
  final dynamic genderId;
  final String aadhar;
  final String pancard;
  final String imagePath;
  final String joiningDate;
  final String bloodGroup;
  final String edu;
  final String qualification;
  final String cast;
  final String religion;
  final dynamic religionId;
  final String category;
  final String maritialStatus;
  final String anniversaryDate;
  final String workLocationName;
  final String designation;
  final int desgId;
  final int stateLgdCode;
  final int distLgdCode;
  final int talLgdCode;
  final int gpLgdCode;
  final int desgLevelId;
  final String accountNo;
  final String bankName;
  final String branchName;
  final String ifscCode;
  final String omtCscId;
  final String ipAddress;
  final String bCompany;
  final String bAddress;
  final String bEmail;
  final String bMobile;
  final String categoryId;
  final String maritialStatusId;
  final int hllDistrictId;
  final int centerId;
  final String facilityTypeCategory;
  final String facilityType;
  final int facilityCode;
  final String facilityName;
  final String cityName;
  final int cityCode;
  final String labName;
  final int labCode;
  final String distName;
  final String zipCode;
  final double latitude;
  final double longitude;
  final String updateLocation;
  final bool isActive;
  final int divisionId;
  final String divisionName;

  ProfileData({
    required this.empCode,
    required this.subOrgWiseDesgId,
    required this.subOrgId,
    required this.subOrgName,
    required this.orgId,
    required this.orgName,
    required this.projectId,
    required this.projectName,
    required this.username,
    required this.name,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.spouseName,
    required this.children,
    required this.motherName,
    required this.fatherName,
    required this.voterId,
    required this.perEmail,
    required this.perMobile,
    required this.pAddress,
    required this.cAddress,
    required this.dob,
    required this.gender,
    this.genderId,
    required this.aadhar,
    required this.pancard,
    required this.imagePath,
    required this.joiningDate,
    required this.bloodGroup,
    required this.edu,
    required this.qualification,
    required this.cast,
    required this.religion,
    this.religionId,
    required this.category,
    required this.maritialStatus,
    required this.anniversaryDate,
    required this.workLocationName,
    required this.designation,
    required this.desgId,
    required this.stateLgdCode,
    required this.distLgdCode,
    required this.talLgdCode,
    required this.gpLgdCode,
    required this.desgLevelId,
    required this.accountNo,
    required this.bankName,
    required this.branchName,
    required this.ifscCode,
    required this.omtCscId,
    required this.ipAddress,
    required this.bCompany,
    required this.bAddress,
    required this.bEmail,
    required this.bMobile,
    required this.categoryId,
    required this.maritialStatusId,
    required this.hllDistrictId,
    required this.centerId,
    required this.facilityTypeCategory,
    required this.facilityType,
    required this.facilityCode,
    required this.facilityName,
    required this.cityName,
    required this.cityCode,
    required this.labName,
    required this.labCode,
    required this.distName,
    required this.zipCode,
    required this.latitude,
    required this.longitude,
    required this.updateLocation,
    required this.isActive,
    required this.divisionId,
    required this.divisionName,
  });

  ProfileData copyWith({
    int? empCode,
    int? subOrgWiseDesgId,
    int? subOrgId,
    String? subOrgName,
    int? orgId,
    String? orgName,
    int? projectId,
    String? projectName,
    String? username,
    String? name,
    String? firstName,
    String? middleName,
    String? lastName,
    String? spouseName,
    int? children,
    String? motherName,
    String? fatherName,
    String? voterId,
    String? perEmail,
    String? perMobile,
    String? pAddress,
    String? cAddress,
    String? dob,
    String? gender,
    dynamic genderId,
    String? aadhar,
    String? pancard,
    String? imagePath,
    String? joiningDate,
    String? bloodGroup,
    String? edu,
    String? qualification,
    String? cast,
    String? religion,
    dynamic religionId,
    String? category,
    String? maritialStatus,
    String? anniversaryDate,
    String? workLocationName,
    String? designation,
    int? desgId,
    int? stateLgdCode,
    int? distLgdCode,
    int? talLgdCode,
    int? gpLgdCode,
    int? desgLevelId,
    String? accountNo,
    String? bankName,
    String? branchName,
    String? ifscCode,
    String? omtCscId,
    String? ipAddress,
    String? bCompany,
    String? bAddress,
    String? bEmail,
    String? bMobile,
    String? categoryId,
    String? maritialStatusId,
    int? hllDistrictId,
    int? centerId,
    String? facilityTypeCategory,
    String? facilityType,
    int? facilityCode,
    String? facilityName,
    String? cityName,
    int? cityCode,
    String? labName,
    int? labCode,
    String? distName,
    String? zipCode,
    double? latitude,
    double? longitude,
    String? updateLocation,
    bool? isActive,
    int? divisionId,
    String? divisionName,
  }) {
    return ProfileData(
      empCode: empCode ?? this.empCode,
      subOrgWiseDesgId: subOrgWiseDesgId ?? this.subOrgWiseDesgId,
      subOrgId: subOrgId ?? this.subOrgId,
      subOrgName: subOrgName ?? this.subOrgName,
      orgId: orgId ?? this.orgId,
      orgName: orgName ?? this.orgName,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      username: username ?? this.username,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      spouseName: spouseName ?? this.spouseName,
      children: children ?? this.children,
      motherName: motherName ?? this.motherName,
      fatherName: fatherName ?? this.fatherName,
      voterId: voterId ?? this.voterId,
      perEmail: perEmail ?? this.perEmail,
      perMobile: perMobile ?? this.perMobile,
      pAddress: pAddress ?? this.pAddress,
      cAddress: cAddress ?? this.cAddress,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      genderId: genderId ?? this.genderId,
      aadhar: aadhar ?? this.aadhar,
      pancard: pancard ?? this.pancard,
      imagePath: imagePath ?? this.imagePath,
      joiningDate: joiningDate ?? this.joiningDate,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      edu: edu ?? this.edu,
      qualification: qualification ?? this.qualification,
      cast: cast ?? this.cast,
      religion: religion ?? this.religion,
      religionId: religionId ?? this.religionId,
      category: category ?? this.category,
      maritialStatus: maritialStatus ?? this.maritialStatus,
      anniversaryDate: anniversaryDate ?? this.anniversaryDate,
      workLocationName: workLocationName ?? this.workLocationName,
      designation: designation ?? this.designation,
      desgId: desgId ?? this.desgId,
      stateLgdCode: stateLgdCode ?? this.stateLgdCode,
      distLgdCode: distLgdCode ?? this.distLgdCode,
      talLgdCode: talLgdCode ?? this.talLgdCode,
      gpLgdCode: gpLgdCode ?? this.gpLgdCode,
      desgLevelId: desgLevelId ?? this.desgLevelId,
      accountNo: accountNo ?? this.accountNo,
      bankName: bankName ?? this.bankName,
      branchName: branchName ?? this.branchName,
      ifscCode: ifscCode ?? this.ifscCode,
      omtCscId: omtCscId ?? this.omtCscId,
      ipAddress: ipAddress ?? this.ipAddress,
      bCompany: bCompany ?? this.bCompany,
      bAddress: bAddress ?? this.bAddress,
      bEmail: bEmail ?? this.bEmail,
      bMobile: bMobile ?? this.bMobile,
      categoryId: categoryId ?? this.categoryId,
      maritialStatusId: maritialStatusId ?? this.maritialStatusId,
      hllDistrictId: hllDistrictId ?? this.hllDistrictId,
      centerId: centerId ?? this.centerId,
      facilityTypeCategory: facilityTypeCategory ?? this.facilityTypeCategory,
      facilityType: facilityType ?? this.facilityType,
      facilityCode: facilityCode ?? this.facilityCode,
      facilityName: facilityName ?? this.facilityName,
      cityName: cityName ?? this.cityName,
      cityCode: cityCode ?? this.cityCode,
      labName: labName ?? this.labName,
      labCode: labCode ?? this.labCode,
      distName: distName ?? this.distName,
      zipCode: zipCode ?? this.zipCode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      updateLocation: updateLocation ?? this.updateLocation,
      isActive: isActive ?? this.isActive,
      divisionId: divisionId ?? this.divisionId,
      divisionName: divisionName ?? this.divisionName,
    );
  }

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      empCode: json['EmpCode'] ?? 0,
      subOrgWiseDesgId: json['SUBORGWISEDESGID'] ?? 0,
      subOrgId: json['SUBORGID'] ?? 0,
      subOrgName: json['SubOrgName'] ?? '',
      orgId: json['OrgId'] ?? 0,
      orgName: json['OrgName'] ?? '',
      projectId: json['ProjectId'] ?? 0,
      projectName: json['ProjectName'] ?? '',
      username: json['USERNAME'] ?? '',
      name: json['name'] ?? '',
      firstName: json['FirstName'] ?? '',
      middleName: json['MiddleName'] ?? '',
      lastName: json['LastName'] ?? '',
      spouseName: json['SpouseName'] ?? '',
      children: json['Children'] ?? 0,
      motherName: json['MotherName'] ?? '',
      fatherName: json['FatherName'] ?? '',
      voterId: json['VoterId'] ?? '',
      perEmail: json['per_email'] ?? '',
      perMobile: json['per_mobile'] ?? '',
      pAddress: json['PAddress'] ?? '',
      cAddress: json['CAddress'] ?? '',
      dob: json['dob'] ?? '',
      gender: json['gender'] ?? '',
      genderId: json['genderID'],
      aadhar: json['Aadhar'] ?? '',
      pancard: json['pancard'] ?? '',
      imagePath: json['ImagePath'] ?? '',
      joiningDate: json['joiningdate'] ?? '',
      bloodGroup: json['bloodgroup'] ?? '',
      edu: json['edu'] ?? '',
      qualification: json['qualification'] ?? '',
      cast: json['cast'] ?? '',
      religion: json['religion'] ?? '',
      religionId: json['ReligionId'],
      category: json['category'] ?? '',
      maritialStatus: json['Maritialstatus'] ?? '',
      anniversaryDate: json['anniversarydate'] ?? '',
      workLocationName: json['WorkLocationName'] ?? '',
      designation: json['Designation'] ?? '',
      desgId: json['DESGID'] ?? 0,
      stateLgdCode: json['STATELGDCODE'] ?? 0,
      distLgdCode: json['DISTLGDCODE'] ?? 0,
      talLgdCode: json['TALLGDCODE'] ?? 0,
      gpLgdCode: json['GPLGDCODE'] ?? 0,
      desgLevelId: json['DESGLEVELID'] ?? 0,
      accountNo: json['accountno'] ?? '',
      bankName: json['bankname'] ?? '',
      branchName: json['branchname'] ?? '',
      ifscCode: json['ifsccode'] ?? '',
      omtCscId: json['OMTCSCID'] ?? '',
      ipAddress: json['IPADDRESS'] ?? '',
      bCompany: json['BCompany'] ?? '',
      bAddress: json['BAddress'] ?? '',
      bEmail: json['BEmail'] ?? '',
      bMobile: json['BMobile'] ?? '',
      categoryId: json['CategoryId'] ?? '',
      maritialStatusId: json['MaritialstatusId'] ?? '',
      hllDistrictId: json['HLLDISTRICTID'] ?? 0,
      centerId: json['CenterID'] ?? 0,
      facilityTypeCategory: json['FacilityTypeCategory'] ?? '',
      facilityType: json['FacilityType'] ?? '',
      facilityCode: json['FacilityCode'] ?? 0,
      facilityName: json['FacilityName'] ?? '',
      cityName: json['CityName'] ?? '',
      cityCode: json['CityCode'] ?? 0,
      labName: json['LabName'] ?? '',
      labCode: json['Labcode'] ?? 0,
      distName: json['DISTNAME'] ?? '',
      zipCode: json['ZipCode'] ?? '',
      latitude: (json['Latitude'] ?? 0).toDouble(),
      longitude: (json['Langitude'] ?? 0).toDouble(),
      updateLocation: json['UpdateLocation'] ?? '',
      isActive: json['ISACTIVE'] ?? false,
      divisionId: json['DivisionId'] ?? 0,
      divisionName: json['DivisionName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'EmpCode': empCode,
      'SUBORGWISEDESGID': subOrgWiseDesgId,
      'SUBORGID': subOrgId,
      'SubOrgName': subOrgName,
      'OrgId': orgId,
      'OrgName': orgName,
      'ProjectId': projectId,
      'ProjectName': projectName,
      'USERNAME': username,
      'name': name,
      'FirstName': firstName,
      'MiddleName': middleName,
      'LastName': lastName,
      'SpouseName': spouseName,
      'Children': children,
      'MotherName': motherName,
      'FatherName': fatherName,
      'VoterId': voterId,
      'per_email': perEmail,
      'per_mobile': perMobile,
      'PAddress': pAddress,
      'CAddress': cAddress,
      'dob': dob,
      'gender': gender,
      'genderID': genderId,
      'Aadhar': aadhar,
      'pancard': pancard,
      'ImagePath': imagePath,
      'joiningdate': joiningDate,
      'bloodgroup': bloodGroup,
      'edu': edu,
      'qualification': qualification,
      'cast': cast,
      'religion': religion,
      'ReligionId': religionId,
      'category': category,
      'Maritialstatus': maritialStatus,
      'anniversarydate': anniversaryDate,
      'WorkLocationName': workLocationName,
      'Designation': designation,
      'DESGID': desgId,
      'STATELGDCODE': stateLgdCode,
      'DISTLGDCODE': distLgdCode,
      'TALLGDCODE': talLgdCode,
      'GPLGDCODE': gpLgdCode,
      'DESGLEVELID': desgLevelId,
      'accountno': accountNo,
      'bankname': bankName,
      'branchname': branchName,
      'ifsccode': ifscCode,
      'OMTCSCID': omtCscId,
      'IPADDRESS': ipAddress,
      'BCompany': bCompany,
      'BAddress': bAddress,
      'BEmail': bEmail,
      'BMobile': bMobile,
      'CategoryId': categoryId,
      'MaritialstatusId': maritialStatusId,
      'HLLDISTRICTID': hllDistrictId,
      'CenterID': centerId,
      'FacilityTypeCategory': facilityTypeCategory,
      'FacilityType': facilityType,
      'FacilityCode': facilityCode,
      'FacilityName': facilityName,
      'CityName': cityName,
      'CityCode': cityCode,
      'LabName': labName,
      'Labcode': labCode,
      'DISTNAME': distName,
      'ZipCode': zipCode,
      'Latitude': latitude,
      'Langitude': longitude,
      'UpdateLocation': updateLocation,
      'ISACTIVE': isActive,
      'DivisionId': divisionId,
      'DivisionName': divisionName,
    };
  }
}
