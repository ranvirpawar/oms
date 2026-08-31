// lib/models/bag_model_new.dart

class BagTransactionResponse {
  final String status;
  final String message;
  final List<BagDetail>? output;

  BagTransactionResponse({
    required this.status,
    required this.message,
    this.output,
  });

  factory BagTransactionResponse.fromJson(Map<String, dynamic> json) {
    return BagTransactionResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      output: json['output'] != null
          ? (json['output'] as List)
              .map((item) => BagDetail.fromJson(item))
              .toList()
          : null,
    );
  }
}

class BagDetail {
  final int transactionID;
  final String barcodeFor;
  final String category;
  final int capacity;
  final String bagcode;
  final bool isEmpty;
  final int bagOpen;
  final int tubecount;
  final int vacant;

  BagDetail({
    required this.transactionID,
    required this.barcodeFor,
    required this.category,
    required this.capacity,
    required this.bagcode,
    required this.isEmpty,
    required this.bagOpen,
    required this.tubecount,
    required this.vacant,
  });

  factory BagDetail.fromJson(Map<String, dynamic> json) {
    return BagDetail(
      transactionID: json['TransactionID'] ?? 0,
      barcodeFor: json['BarcodeFor'] ?? '',
      category: json['Category'] ?? '',
      capacity: json['Capacity'] ?? 0,
      bagcode: json['Bagcode'] ?? '',
      isEmpty: json['IsEmpty'] ?? false,
      bagOpen: json['BagOpen'] ?? 0,
      tubecount: json['Tubecount'] ?? 0,
      vacant: json['Vacant'] ?? 0,
    );
  }
}

class StatusUpdateResponse {
  final String status;
  final String message;

  StatusUpdateResponse({
    required this.status,
    required this.message,
  });

  factory StatusUpdateResponse.fromJson(Map<String, dynamic> json) {
    return StatusUpdateResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
    );
  }
}