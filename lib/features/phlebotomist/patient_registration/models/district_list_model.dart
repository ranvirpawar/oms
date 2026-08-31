class DistrictModel {
  final int? distrcitId;
  final String? districtName;
  final int? districtCode;
  final int? stateId;
  final int? distLgdCode;
  final int? divisionId;
  final String? distName;

  DistrictModel({
    required this.distrcitId,
    required this.districtName,
    required this.districtCode,
    required this.stateId,
    required this.distLgdCode,
    required this.divisionId,
    required this.distName,
  });

  factory DistrictModel.fromJson(Map<String, dynamic> json) {
    return DistrictModel(
      distrcitId: json['distrcitId'],
      districtName: json['districtName'],
      districtCode: json['DistrictCode'],
      stateId: json['stateId'],
      distLgdCode: json['DISTLGDCODE'],
      divisionId: json['DivisionId'],
      distName: json['DISTNAME'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'distrcitId': distrcitId,
      'districtName': districtName,
      'DistrictCode': districtCode,
      'stateId': stateId,
      'DISTLGDCODE': distLgdCode,
      'DivisionId': divisionId,
      'DISTNAME': distName,
    };
  }
}
