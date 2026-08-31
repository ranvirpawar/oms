class FacilityTypeModel {
  final int ftypeId;
  final String fType;
  final int patientCount;
  final int testCount;

  FacilityTypeModel({
    required this.ftypeId,
    required this.fType,
    required this.patientCount,
    required this.testCount,
  });

  factory FacilityTypeModel.fromJson(Map<String, dynamic> json) {
    return FacilityTypeModel(
      ftypeId: json['Ftypeid'] ?? 0,
      fType: json['FType'] ?? '',
      patientCount: json['PatientCount'] ?? 0,
      testCount: json['Testcount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Ftypeid': ftypeId,
      'FType': fType,
      'PatientCount': patientCount,
      'Testcount': testCount,
    };
  }
}

class FacilityModel {
  final int facilityId;
  final String facilityName;
  final int ftypeId;
  final String fType;
  final int patientCount;
  final int testCount;

  FacilityModel({
    required this.facilityId,
    required this.facilityName,
    required this.ftypeId,
    required this.fType,
    required this.patientCount,
    required this.testCount,
  });

  factory FacilityModel.fromJson(Map<String, dynamic> json) {
    return FacilityModel(
      facilityId: json['Facilitycode'] ?? 0,
      facilityName: json['facilityname'] ?? '',
      ftypeId: json['Ftypeid'] ?? 0,
      fType: json['FType'] ?? '',
      patientCount: json['PatientCount'] ?? 0,
      testCount: json['Testcount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Facilitycode': facilityId,
      'facilityname': facilityName,
      'Ftypeid': ftypeId,
      'FType': fType,
      'PatientCount': patientCount,
      'Testcount': testCount,
    };
  }
}
