class BeneficiaryConsentResponse {
  final String status;
  final String message;
  final List<BeneficiaryConsent> output;

  BeneficiaryConsentResponse({
    required this.status,
    required this.message,
    required this.output,
  });

  factory BeneficiaryConsentResponse.fromJson(Map<String, dynamic> json) {
    return BeneficiaryConsentResponse(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      output: json['output'] is List
          ? (json['output'] as List)
          .map(
            (item) => BeneficiaryConsent.fromJson(
          item as Map<String, dynamic>,
        ),
      )
          .toList()
          : [],
    );
  }

  bool get isSuccess => status.toLowerCase() == 'success';

  BeneficiaryConsent? get consent {
    if (output.isEmpty) return null;
    return output.first;
  }

  bool get hasConsent => consent?.isConsent == 1;

  bool get isConsentWithdrawn => consent?.isConsent == 2;

  bool get hasConsentStatus => consent?.isConsent != null;
}

class BeneficiaryConsent {
  final int? isConsent;

  BeneficiaryConsent({
    required this.isConsent,
  });

  factory BeneficiaryConsent.fromJson(Map<String, dynamic> json) {
    return BeneficiaryConsent(
      isConsent: json['IsConsent'] is int
          ? json['IsConsent'] as int
          : int.tryParse(json['IsConsent']?.toString() ?? ''),
    );
  }
}