class HandoverSubmitResponse {
  final bool isSuccess;
  final String message;

  HandoverSubmitResponse({required this.isSuccess, required this.message});

  factory HandoverSubmitResponse.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString().toLowerCase();
    final isSuccess = status == 'success' || status == '1' || status == 'true';
    return HandoverSubmitResponse(
      isSuccess: isSuccess,
      message: json['message']?.toString() ?? '',
    );
  }
}

// new