import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart'; // adjust depth if needed

/// How urgent a facility is right now, derived from its TAT vs the
/// standard TAT for that facility type — never hardcoded per-status.
enum FacilityUrgency { breached, warning, onTrack, notStarted, completedLate, completed }

extension FacilityUrgencyX on FacilityUrgency {
  /// Lower = shown first when sorting.
  int get priority {
    switch (this) {
      case FacilityUrgency.breached:
        return 0;
      case FacilityUrgency.warning:
        return 1;
      case FacilityUrgency.onTrack:
        return 2;
      case FacilityUrgency.completedLate:
        return 3;
      case FacilityUrgency.notStarted:
        return 4;
      case FacilityUrgency.completed:
        return 5;
    }
  }

  String get label {
    switch (this) {
      case FacilityUrgency.breached:
        return 'TAT Breached';
      case FacilityUrgency.warning:
        return 'Approaching TAT';
      case FacilityUrgency.onTrack:
        return 'On Track';
      case FacilityUrgency.completedLate:
        return 'Closed (Late)';
      case FacilityUrgency.notStarted:
        return 'Not Started';
      case FacilityUrgency.completed:
        return 'Completed';
    }
  }

  Color get color {
    switch (this) {
      case FacilityUrgency.breached:
        return AppColors.redText;
      case FacilityUrgency.warning:
        return AppColors.amberText;
      case FacilityUrgency.onTrack:
        return AppColors.blueText;
      case FacilityUrgency.completedLate:
        return AppColors.amberText;
      case FacilityUrgency.notStarted:
        return AppColors.grayText;
      case FacilityUrgency.completed:
        return AppColors.greenText;
    }
  }

  Color get bgColor {
    switch (this) {
      case FacilityUrgency.breached:
        return AppColors.redLight;
      case FacilityUrgency.warning:
        return AppColors.amberLight;
      case FacilityUrgency.onTrack:
        return AppColors.blueLight;
      case FacilityUrgency.completedLate:
        return AppColors.amberLight;
      case FacilityUrgency.notStarted:
        return AppColors.grayLight;
      case FacilityUrgency.completed:
        return AppColors.greenLight;
    }
  }
}

class FacilityModel {
  final String ward;
  final String facilityName;
  final int facilityCode;
  final String fType;
  final String? bagcode;
  final String? phleboName;
  final String? phleboPhone;
  final String rbName;
  final String? rbPhone;
  final bool? isBagClosed;
  final String timeElapsed;
  final String? status; // raw string from API, e.g. "In Transit", "Bag Accepted" — never hardcoded elsewhere
  final int? tubecount;
  final int? processid;
  final double? tatTimeInHrs; // final/measured TAT once available
  final double stdTatTime; // target TAT for this facility/process
  final int? processComplete;
  final int registrationCount;

  const FacilityModel({
    required this.ward,
    required this.facilityName,
    required this.facilityCode,
    required this.fType,
    this.bagcode,
    this.phleboName,
    this.phleboPhone,
    required this.rbName,
    this.rbPhone,
    this.isBagClosed,
    required this.timeElapsed,
    this.status,
    this.tubecount,
    this.processid,
    this.tatTimeInHrs,
    required this.stdTatTime,
    this.processComplete,
    required this.registrationCount,
  });

  factory FacilityModel.fromJson(Map<String, dynamic> json) {
    String? cleanString(dynamic v) {
      final s = v?.toString().trim();
      return (s == null || s.isEmpty) ? null : s;
    }

    return FacilityModel(
      ward: json['Ward']?.toString() ?? '',
      facilityName: json['FacilityName']?.toString() ?? '',
      facilityCode: (json['FacilityCode'] as num?)?.toInt() ?? 0,
      fType: json['FType']?.toString() ?? '',
      bagcode: cleanString(json['Bagcode']),
      phleboName: cleanString(json['PhleboName']),
      phleboPhone: cleanString(json['PhleboMobile']),
      rbName: cleanString(json['RbName']) ?? '',
      rbPhone: cleanString(json['RbPhone']),
      isBagClosed: json['IsBagClosed'] as bool?,
      timeElapsed: json['TimeElapsed']?.toString() ?? '',
      status: cleanString(json['Status']),
      tubecount: (json['Tubecount'] as num?)?.toInt(),
      processid: (json['Processid'] as num?)?.toInt(),
      tatTimeInHrs: (json['TAT_TIME_in_HRS'] as num?)?.toDouble(),
      stdTatTime: (json['STD_TAT_TIME'] as num?)?.toDouble() ?? 3.0,
      processComplete: (json['Process_Complete'] as num?)?.toInt(),
      registrationCount: (json['Registration_count'] as num?)?.toInt() ?? 0,
    );
  }

  bool get hasBag => bagcode != null;

  /// Parses a live "N Hours ago" / "N Min ago" style string into hours.
  /// Returns null if TimeElapsed doesn't carry a parseable duration.
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

  /// The label the UI should show for this facility's stage — falls back
  /// gracefully instead of assuming a fixed set of statuses.
  String get displayStatus => status ?? (registrationCount > 0 ? 'Registered' : 'Not Started');

  bool get _isFinishedStatus {
    final s = status?.toLowerCase();
    return s == 'bag accepted' || s == 'bag closed' || s == 'closed' || (isBagClosed == true && tatTimeInHrs != null);
  }

  /// Derives how urgent this facility is right now, purely from the data —
  /// no per-status hardcoding.
  FacilityUrgency get urgency {
    if (!hasBag && processid == null) return FacilityUrgency.notStarted;

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