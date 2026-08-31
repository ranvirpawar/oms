import 'facility_model.dart' show FacilityUrgency, FacilityUrgencyX;

/// Type 4 response — a flat list of bags (not tied to a single facility
/// view), each with its own contact person and TAT. Used by the Bags tab.
class BagModel {
  final String bagcode;
  final String? contactPersonName;
  final String? contactPersonPhone;
  final int? tubecount;
  final int? processid;
  final String? status; // raw string from API, e.g. "Close bag ", "Open bag "
  final String timeElapsed;
  final double? tatTimeInHrs;
  final double stdTatTime;
  final int? processComplete;

  const BagModel({
    required this.bagcode,
    this.contactPersonName,
    this.contactPersonPhone,
    this.tubecount,
    this.processid,
    this.status,
    required this.timeElapsed,
    this.tatTimeInHrs,
    required this.stdTatTime,
    this.processComplete,
  });

  factory BagModel.fromJson(Map<String, dynamic> json) {
    String? clean(dynamic v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    return BagModel(
      bagcode: json['Bagcode']?.toString() ?? '',
      contactPersonName: clean(json['Contact_person_name']),
      contactPersonPhone: clean(json['Contact_person_Mobile']),
      tubecount: (json['Tubecount'] as num?)?.toInt(),
      processid: (json['Processid'] as num?)?.toInt(),
      // API returns trailing-space statuses ("Close bag ") — clean() trims them.
      status: clean(json['Status']),
      timeElapsed: json['TimeElapsed']?.toString() ?? '',
      tatTimeInHrs: (json['TAT_TIME_in_HRS'] as num?)?.toDouble(),
      stdTatTime: (json['STD_TAT_TIME'] as num?)?.toDouble() ?? 3.0,
      processComplete: (json['Process_Complete'] as num?)?.toInt(),
    );
  }

  String get displayStatus => status ?? 'Unknown';

  double? get liveElapsedHours {
    final match = RegExp(
      r'(\d+(?:\.\d+)?)\s*(hour|hours|hr|hrs|min|mins|minute|minutes|day|days)',
      caseSensitive: false,
    ).firstMatch(timeElapsed);
    if (match == null) return null;

    final value = double.tryParse(match.group(1) ?? '') ?? 0;
    final unit = (match.group(2) ?? '').toLowerCase();

    if (unit.startsWith('day')) return value * 24;
    if (unit.startsWith('min')) return value / 60;
    return value;
  }

  bool get _isFinishedStatus {
    final s = status?.toLowerCase() ?? '';
    return s.contains('close') || s.contains('accept');
  }

  FacilityUrgency get urgency {
    final elapsed = tatTimeInHrs ?? liveElapsedHours;

    if (_isFinishedStatus) {
      if (elapsed != null && elapsed > stdTatTime) return FacilityUrgency.completedLate;
      return FacilityUrgency.completed;
    }

    if (elapsed == null) return FacilityUrgency.onTrack;
    if (elapsed > stdTatTime) return FacilityUrgency.breached;
    if (elapsed >= stdTatTime * 0.7) return FacilityUrgency.warning;
    return FacilityUrgency.onTrack;
  }
}