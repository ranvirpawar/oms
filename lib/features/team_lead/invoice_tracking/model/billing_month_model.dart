class BillingMonthResponse {
  final String status;
  final String message;
  final List<BillingMonth> output;

  BillingMonthResponse({
    required this.status,
    required this.message,
    required this.output,
  });

  factory BillingMonthResponse.fromJson(Map<String, dynamic> json) {
    return BillingMonthResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      output: (json['output'] as List<dynamic>?)
          ?.map((e) => BillingMonth.fromJson(e))
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

class BillingMonth {
  final int monthId;
  final String monthNameEng;

  BillingMonth({
    required this.monthId,
    required this.monthNameEng,
  });

  factory BillingMonth.fromJson(Map<String, dynamic> json) {
    return BillingMonth(
      monthId: json['Month_id'] ?? 0,
      monthNameEng: json['Month_Name_Eng'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Month_id': monthId,
      'Month_Name_Eng': monthNameEng,
    };
  }

  @override
  String toString() => monthNameEng;
}
