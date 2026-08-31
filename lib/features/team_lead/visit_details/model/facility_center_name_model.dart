class FacilityCenterName {
  final int centerId;
  final String centerLabName;
  final double? latitude;
  final double? longitude;

  FacilityCenterName({
    required this.centerId,
    required this.centerLabName,
    this.latitude,
    this.longitude,
  });

  factory FacilityCenterName.fromJson(Map<String, dynamic> json) {
    return FacilityCenterName(
      centerId: json['CenterID'] as int,
      centerLabName: json['Center_Lab_Name'] as String,
      latitude: double.tryParse(json['Latitude']?.toString() ?? ''),
      longitude: double.tryParse(json['Longitude']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'CenterID': centerId,
      'Center_Lab_Name': centerLabName,
      'Latitude': latitude,
      'Longitude': longitude,
    };
  }

  static List<FacilityCenterName> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => FacilityCenterName.fromJson(json)).toList();
  }
}
