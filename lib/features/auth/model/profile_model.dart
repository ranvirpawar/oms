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
