class TrackingCountsModel {
  final int totalFacility;
  final int registeredFacilityCount;
  final int bagClose;
  final int pickup;
  final int handover;
  final int bagAcceptance;

  const TrackingCountsModel({
    required this.totalFacility,
    required this.registeredFacilityCount,
    required this.bagClose,
    required this.pickup,
    required this.handover,
    required this.bagAcceptance,
  });

  int get totalBags => registeredFacilityCount + bagAcceptance + handover + pickup + bagClose;

  factory TrackingCountsModel.fromJson(Map<String, dynamic> json) {
    return TrackingCountsModel(
      totalFacility:           (json['TotalFacility'] as num?)?.toInt() ?? 0,
      registeredFacilityCount: (json['RegisteredFacilitycount'] as num?)?.toInt() ?? 0,
      bagClose:                (json['Bagclose'] as num?)?.toInt() ?? 0,
      pickup:                  (json['Pickup'] as num?)?.toInt() ?? 0,
      handover:                (json['Handover'] as num?)?.toInt() ?? 0,
      bagAcceptance:           (json['BagAcceptance'] as num?)?.toInt() ?? 0,
    );
  }
}
