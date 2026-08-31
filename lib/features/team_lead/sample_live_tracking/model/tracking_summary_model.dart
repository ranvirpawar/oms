class TrackingSummaryModel {
  final int acceptancePending;
  final int inRegistration;
  final int inTransit;
  final int pendingPickup;

  const TrackingSummaryModel({
    required this.acceptancePending,
    required this.inRegistration,
    required this.inTransit,
    required this.pendingPickup,
  });

  factory TrackingSummaryModel.fromJson(Map<String, dynamic> json) {
    return TrackingSummaryModel(
      acceptancePending: int.tryParse(json['Acceptance Pending']?.toString() ?? '0') ?? 0,
      inRegistration:    int.tryParse(json['In Registration']?.toString() ?? '0') ?? 0,
      inTransit:         int.tryParse(json['In Transit']?.toString() ?? '0') ?? 0,
      pendingPickup:     int.tryParse(json['Pending Pickup']?.toString() ?? '0') ?? 0,
    );
  }
}
