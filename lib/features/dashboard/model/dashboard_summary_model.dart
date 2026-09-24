import 'dart:convert';

PhleboDashboardSummary phleboDashboardSummaryFromJson(String str) =>
    PhleboDashboardSummary.fromJson(json.decode(str));
String phleboDashboardSummaryToJson(PhleboDashboardSummary data) =>
    json.encode(data.toJson());

class PhleboDashboardSummary {
  final String status;
  final String message;
  final List<DashboardSummaryItem> output;

  bool get isEmptyResult =>
      status.trim().toLowerCase() == 'fail' &&
      message.trim().toLowerCase() == 'no record found' &&
      output.isEmpty;

  PhleboDashboardSummary({
    required this.status,
    required this.message,
    required this.output,
  });
  factory PhleboDashboardSummary.fromJson(Map<String, dynamic> json) =>
      PhleboDashboardSummary(
        status: json['status']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        output: (json['output'] as List? ?? [])
            .map(
              (item) =>
                  DashboardSummaryItem.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
      );
  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'output': output.map((item) => item.toJson()).toList(),
  };
}

class DashboardSummaryItem {
  final int userId;
  final int assignedPatientsCount;
  final int clinicCollectionRequestCount;
  final int homeRequestCount;
  final int servedRequests;
  final int readyForPickUp;
  final int pickedUp;
  final int submitToLab;
  final int acceptedInLab;
  const DashboardSummaryItem({
    this.userId = 0,
    this.assignedPatientsCount = 0,
    this.clinicCollectionRequestCount = 0,
    this.homeRequestCount = 0,
    this.servedRequests = 0,
    this.readyForPickUp = 0,
    this.pickedUp = 0,
    this.submitToLab = 0,
    this.acceptedInLab = 0,
  });
  static int _count(dynamic value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
  factory DashboardSummaryItem.fromJson(Map<String, dynamic> json) =>
      DashboardSummaryItem(
        userId: _count(json['UserID']),
        assignedPatientsCount: _count(json['AssignedPatientsCount']),
        clinicCollectionRequestCount: _count(
          json['ClinicCollectionRequestCount'],
        ),
        homeRequestCount: _count(json['HomeRequestCount']),
        servedRequests: _count(json['ServedRequests']),
        readyForPickUp: _count(json['ReadyForPickUp']),
        pickedUp: _count(json['PickedUp']),
        submitToLab: _count(json['SubmittoLab']),
        acceptedInLab: _count(json['AcceptedinLab']),
      );
  Map<String, dynamic> toJson() => {
    'UserID': userId,
    'AssignedPatientsCount': assignedPatientsCount,
    'ClinicCollectionRequestCount': clinicCollectionRequestCount,
    'HomeRequestCount': homeRequestCount,
    'ServedRequests': servedRequests,
    'ReadyForPickUp': readyForPickUp,
    'PickedUp': pickedUp,
    'SubmittoLab': submitToLab,
    'AcceptedinLab': acceptedInLab,
  };
}
