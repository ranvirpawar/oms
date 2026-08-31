class NewFacilityModel {
  final int facilityCode;
  final String facilityName;

  NewFacilityModel({
    required this.facilityCode,
    required this.facilityName,
  });

  factory NewFacilityModel.fromJson(Map<String, dynamic> json) {
    return NewFacilityModel(
      facilityCode: json['facilitycode'] as int,
      facilityName: json['Facilityname'] as String,
    );
  }

  @override
  String toString() => 'NewFacilityModel($facilityCode, $facilityName)';
}