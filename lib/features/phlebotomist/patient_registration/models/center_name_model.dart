class CenterModel {
  final int centerId;
  final String centerName;

  CenterModel({required this.centerId, required this.centerName});

  factory CenterModel.fromJson(Map<String, dynamic> json) {
    return CenterModel(
      centerId: json['centerId'],
      centerName: json['centername'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'centerId': centerId,
      'centername': centerName,
    };
  }
}
