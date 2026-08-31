class ConsentStatusModel {
  final String consentStatus;


  ConsentStatusModel({
    required this.consentStatus,
  });

  factory ConsentStatusModel.fromJson(Map<String, dynamic> json) {
    return ConsentStatusModel(
      consentStatus: json['ConsentStatus'] ?? '',

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ConsentStatus': consentStatus,
    };
  }
}
