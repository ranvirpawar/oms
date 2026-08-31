class VisitResponseModel {
  final String status;
  final String message;
  final List<SurveyOutput> output;

  VisitResponseModel({
    required this.status,
    required this.message,
    required this.output,
  });

  factory VisitResponseModel.fromJson(Map<String, dynamic> json) {
    return VisitResponseModel(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      output: (json['output'] as List<dynamic>?)
          ?.map((item) => SurveyOutput.fromJson(item))
          .toList() ??
          [],
    );
  }
}

class SurveyOutput {
  final int surveyId;

  SurveyOutput({required this.surveyId});

  factory SurveyOutput.fromJson(Map<String, dynamic> json) {
    return SurveyOutput(
      surveyId: int.tryParse(json['SurveyID']?.toString() ?? '0') ?? 0,
    );
  }
}