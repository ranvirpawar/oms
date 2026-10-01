import 'dart:convert';

PhleboDashboardSummary phleboDashboardSummaryFromJson(String str) =>
    PhleboDashboardSummary.fromJson(json.decode(str));
String phleboDashboardSummaryToJson(PhleboDashboardSummary data) =>
    json.encode(data.toJson());

class PhleboDashboardSummary {
  final String status;
  final String message;
  final List<DashboardSummaryItem> output;

  // Preserve the patient/order summary strip; tube totals are a separate series.
  List<DashboardSummaryMetric> get metrics {
    for (final row in output) {
      if (DashboardSummaryItem.normalizeKey(row.rowType) != 'tubecount') {
        return row.metrics;
      }
    }
    return const [];
  }

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
  final String rowType;
  final List<DashboardSummaryMetric> metrics;
  final Map<String, dynamic>? _source;
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
    this.rowType = '',
    this.metrics = const [],
    Map<String, dynamic>? source,
    this.userId = 0,
    this.assignedPatientsCount = 0,
    this.clinicCollectionRequestCount = 0,
    this.homeRequestCount = 0,
    this.servedRequests = 0,
    this.readyForPickUp = 0,
    this.pickedUp = 0,
    this.submitToLab = 0,
    this.acceptedInLab = 0,
  }) : _source = source;
  static String normalizeKey(String key) =>
      key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  static int _count(dynamic value) =>
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
  factory DashboardSummaryItem.fromJson(Map<String, dynamic> json) {
    final metrics = <DashboardSummaryMetric>[];
    for (final entry in json.entries) {
      if (const ['userid', 'rowtype'].contains(normalizeKey(entry.key))) {
        continue;
      }
      if (entry.key.trim().isEmpty) continue;
      // Counts may arrive as numbers, numeric strings or null (displayed as zero).
      final value = entry.value;
      if (value != null &&
          value is! num &&
          num.tryParse(value.toString().trim()) == null) {
        continue;
      }
      metrics.add(DashboardSummaryMetric(key: entry.key, value: _count(value)));
    }
    return DashboardSummaryItem(
      rowType: json['RowType']?.toString() ?? '',
      metrics: List.unmodifiable(metrics),
      source: Map.unmodifiable(json),
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
  }
  Map<String, dynamic> toJson() => {
    if (_source != null)
      ..._source
    else ...{
      'UserID': userId,
      'AssignedPatientsCount': assignedPatientsCount,
      'ClinicCollectionRequestCount': clinicCollectionRequestCount,
      'HomeRequestCount': homeRequestCount,
      'ServedRequests': servedRequests,
      'ReadyForPickUp': readyForPickUp,
      'PickedUp': pickedUp,
      'SubmittoLab': submitToLab,
      'AcceptedinLab': acceptedInLab,
    },
  };
}

// Proposed backend contract (for discussion; the parser above uses today's API):
// {
//   "status": "Success",
//   "message": "Dashboard summary",
//   "output": [{
//     "userId": 48,
//     "series": "patientCount",
//     "metrics": [
//       {"key": "submittedToLab", "label": "Submitted To Lab", "value": 0},
//       {"key": "acceptedInLab", "label": "Accepted In Lab", "value": 0}
//     ]
//   }, {"userId": 48, "series": "tubeCount", "metrics": []}]
// }
// Please use stable series/key identifiers (no spelling/casing variants), explicit
// display labels, integer counts including zero, and arrays in display order.
// Return output: [] when no records exist. Keep metadata outside metrics; labels
// must not be JSON property names. This lets any role add/reorder/rename metrics
// without an app release and keeps patient/order counts separate from tube counts.
class DashboardSummaryMetric {
  final String key;
  final int value;

  const DashboardSummaryMetric({required this.key, required this.value});

  String get label => key
      .replaceAllMapped(RegExp(r'([a-z0-9])([A-Z])'), (m) => '${m[1]} ${m[2]}')
      .replaceAllMapped(
        RegExp(r'([A-Z])([A-Z][a-z])'),
        (m) => '${m[1]} ${m[2]}',
      )
      .replaceAll(RegExp(r'[_\-\s]+'), ' ')
      .trim()
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? ''
            : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');
}
