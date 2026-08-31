/// Type-1 response — a funnel of how many bags are at each stage today.
/// Replaces the old TrackingSummaryModel, which assumed a fixed set of
/// status buckets that the API no longer returns.
class SampleFlowSummaryModel {
  final int openBag;
  final int closeBag;
  final int sampleTransfer;
  final int sampleBagCollected;
  final int sampleBagHandover;
  final int bagSubmitted;
  final int bagAccepted;

  const SampleFlowSummaryModel({
    required this.openBag,
    required this.closeBag,
    required this.sampleTransfer,
    required this.sampleBagCollected,
    required this.sampleBagHandover,
    required this.bagSubmitted,
    required this.bagAccepted,
  });

  factory SampleFlowSummaryModel.fromJson(Map<String, dynamic> json) {
    int i(String key) => (json[key] as num?)?.toInt() ?? 0;

    return SampleFlowSummaryModel(
      openBag: i('Open bag'),
      closeBag: i('Close bag'),
      sampleTransfer: i('Sample transfer'),
      sampleBagCollected: i('Sample bag collected'),
      sampleBagHandover: i('Sample bag handover'),
      bagSubmitted: i('Bag submitted'),
      bagAccepted: i('Bag accepted'),
    );
  }

  static const empty = SampleFlowSummaryModel(
    openBag: 0,
    closeBag: 0,
    sampleTransfer: 0,
    sampleBagCollected: 0,
    sampleBagHandover: 0,
    bagSubmitted: 0,
    bagAccepted: 0,
  );
}