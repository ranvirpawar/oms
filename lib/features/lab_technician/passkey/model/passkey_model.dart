// Models
class PasskeyResponse {
  final String status;
  final String message;
  final List<PasskeyData> output;

  PasskeyResponse({
    required this.status,
    required this.message,
    required this.output,
  });

  factory PasskeyResponse.fromJson(Map<String, dynamic> json) {
    return PasskeyResponse(
      status: json['status'],
      message: json['message'],
      output: (json['output'] as List)
          .map((item) => PasskeyData.fromJson(item))
          .toList(),
    );
  }
}

class PasskeyData {
  final String passkey;
  final int userId;
  final String generatedAt;

  PasskeyData({
    required this.passkey,
    required this.userId,
    required this.generatedAt,
  });

  factory PasskeyData.fromJson(Map<String, dynamic> json) {
    return PasskeyData(
      passkey: json['passkey'],
      userId: json['Userid'],
      generatedAt: json['GeneratedAt'],
    );
  }
}