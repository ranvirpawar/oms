/// GetBagDetails_Rb_trackingDahsboard — type 1: status timeline entry.
class BagStatusEventModel {
  final int facilityCode;
  final String facilityName;
  final String status;

  const BagStatusEventModel({
    required this.facilityCode,
    required this.facilityName,
    required this.status,
  });

  factory BagStatusEventModel.fromJson(Map<String, dynamic> json) {
    return BagStatusEventModel(
      facilityCode: (json['Facilitycode'] as num?)?.toInt() ?? 0,
      facilityName: json['FacilityName']?.toString() ?? '',
      // API has a typo in the key name ("STatus") — read defensively.
      status: (json['STatus'] ?? json['Status'])?.toString() ?? '',
    );
  }
}

/// GetBagDetails_Rb_trackingDahsboard — type 2: tube content breakdown.
class TubeContentModel {
  final int sessionId;
  final String ward;
  final String facilityName;
  final String tubeContent;
  final int tubeCount;

  const TubeContentModel({
    required this.sessionId,
    required this.ward,
    required this.facilityName,
    required this.tubeContent,
    required this.tubeCount,
  });

  factory TubeContentModel.fromJson(Map<String, dynamic> json) {
    return TubeContentModel(
      sessionId: (json['sessionid'] as num?)?.toInt() ?? 0,
      ward: json['Ward']?.toString() ?? '',
      facilityName: json['FacilityName']?.toString() ?? '',
      tubeContent: json['TubeContent']?.toString() ?? '',
      tubeCount: (json['Tubecount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Combined result shown in the facility drill-down sheet.
class BagDrillDownModel {
  final List<BagStatusEventModel> statusEvents;
  final List<TubeContentModel> tubeContents;

  const BagDrillDownModel({
    required this.statusEvents,
    required this.tubeContents,
  });

  int get totalTubes => tubeContents.fold(0, (sum, t) => sum + t.tubeCount);
}