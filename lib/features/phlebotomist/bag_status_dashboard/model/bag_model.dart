// models/bag_status_model.dart
class BagStatusModel {
  final String status;
  final String message;
  final List<BagStatusOutput>? output;

  BagStatusModel({
    required this.status,
    required this.message,
    this.output,
  });

  factory BagStatusModel.fromJson(Map<String, dynamic> json) {
    return BagStatusModel(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      output: json['output'] != null
          ? (json['output'] as List)
          .map((e) => BagStatusOutput.fromJson(e))
          .toList()
          : null,
    );
  }
}

class BagStatusOutput {
  final int transactionID;
  final int bagID;
  final String bagcode;
  final int transitionStatus;
  final String createdOn;

  BagStatusOutput({
    required this.transactionID,
    required this.bagID,
    required this.bagcode,
    required this.transitionStatus,
    required this.createdOn,
  });

  factory BagStatusOutput.fromJson(Map<String, dynamic> json) {
    return BagStatusOutput(
      transactionID: json['TransactionID'] ?? 0,
      bagID: json['BagID'] ?? 0,
      bagcode: json['Bagcode'] ?? '',
      transitionStatus: json['TransitionStatus'] ?? 0,
      createdOn: json['CreatedOn'] ?? '',
    );
  }
}



