class MaritalStatusModel {
  final int maritalStatusId;
  final String maritalStatus;

  MaritalStatusModel({
    required this.maritalStatusId,
    required this.maritalStatus,
  });

  factory MaritalStatusModel.fromJson(Map<String, dynamic> json) {
    return MaritalStatusModel(
      maritalStatusId: json['MARITALSTATUSID'],
      maritalStatus: json['MARITALSTATUS'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'MARITALSTATUSID': maritalStatusId,
      'MARITALSTATUS': maritalStatus,
    };
  }
}
