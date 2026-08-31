class SampleTemperatureResponse {
  final String status;
  final String message;
  final List<SampleTemperatureData> output;

  SampleTemperatureResponse({
    required this.status,
    required this.message,
    required this.output,
  });

  factory SampleTemperatureResponse.fromJson(Map<String, dynamic> json) {
    return SampleTemperatureResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      output: (json['output'] as List<dynamic>?)
          ?.map((e) => SampleTemperatureData.fromJson(e))
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

class SampleTemperatureData {
  final int sampleTempId;
  final String sampleTempName;

  SampleTemperatureData({
    required this.sampleTempId,
    required this.sampleTempName,
  });

  factory SampleTemperatureData.fromJson(Map<String, dynamic> json) {
    return SampleTemperatureData(
      sampleTempId: json['SampleTempID'] ?? 0,
      sampleTempName: json['SampleTempName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'SampleTempID': sampleTempId,
      'SampleTempName': sampleTempName,
    };
  }
}
