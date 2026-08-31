class BillingYearResponse {
  final String status;
  final String message;
  final List<BillingYear> output;

  BillingYearResponse({
    required this.status,
    required this.message,
    required this.output,
  });

  factory BillingYearResponse.fromJson(Map<String, dynamic> json) {
    return BillingYearResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      output: (json['output'] as List<dynamic>?)
          ?.map((e) => BillingYear.fromJson(e))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'output': output.map((e) => e.toJson()).toList(),
    };
  }
}

class BillingYear {
  final int yearId;
  final int year;

  BillingYear({
    required this.yearId,
    required this.year,
  });

  factory BillingYear.fromJson(Map<String, dynamic> json) {
    return BillingYear(
      yearId: json['YearId'] ?? 0,
      year: json['Year'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'YearId': yearId,
      'Year': year,
    };
  }

  @override
  String toString() => year.toString();
}
