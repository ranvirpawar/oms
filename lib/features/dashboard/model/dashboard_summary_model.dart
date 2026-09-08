// To parse this JSON data, do
//
//     final phleboDashboardSummary = phleboDashboardSummaryFromJson(jsonString);

import 'dart:convert';

PhleboDashboardSummary phleboDashboardSummaryFromJson(String str) => PhleboDashboardSummary.fromJson(json.decode(str));

String phleboDashboardSummaryToJson(PhleboDashboardSummary data) => json.encode(data.toJson());

class PhleboDashboardSummary {
  final String status;
  final String message;
  final List<Output> output;

  PhleboDashboardSummary({required this.status, required this.message, required this.output});

  factory PhleboDashboardSummary.fromJson(Map<String, dynamic> json) =>
      PhleboDashboardSummary(status: json["status"], message: json["message"], output: List<Output>.from(json["output"].map((x) => Output.fromJson(x))));

  Map<String, dynamic> toJson() => {"status": status, "message": message, "output": List<dynamic>.from(output.map((x) => x.toJson()))};
}

class Output {
  final String assignStatusName;
  final int assignStatusId;
  final int assignstatusCount;

  Output({required this.assignStatusName, required this.assignStatusId, required this.assignstatusCount});

  factory Output.fromJson(Map<String, dynamic> json) => Output(assignStatusName: json["AssignStatusName"], assignStatusId: json["AssignStatusID"], assignstatusCount: json["AssignstatusCount"]);

  Map<String, dynamic> toJson() => {"AssignStatusName": assignStatusName, "AssignStatusID": assignStatusId, "AssignstatusCount": assignstatusCount};
}
