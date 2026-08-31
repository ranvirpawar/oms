class TestStatusModel {
  final String orderId;
  final String serviceName;
  final String statusDescription;

  TestStatusModel({
    required this.orderId,
    required this.serviceName,
    required this.statusDescription,
  });

  factory TestStatusModel.fromJson(Map<String, dynamic> json) => TestStatusModel(
    orderId: json['OrderID'] ?? '',
    serviceName: json['ServiceName'] ?? '',
    statusDescription: json['StatusDescription'] ?? '',
  );

  bool get isReady => statusDescription.toLowerCase().contains('ready');
  bool get isInProcess => !isReady; // everything else is in-processing
}