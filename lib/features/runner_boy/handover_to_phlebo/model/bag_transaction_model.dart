class BagTransactionResponse {
  final String status;
  final String message;
  final List<BagTransaction>? output;

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
          .map((item) => BagTransaction.fromJson(item))
          .toList()
          : null,
    );
  }

  bool get isSuccess => status.toLowerCase() == 'success';
}

class BagTransaction {
  final int transactionId;
  final String barcodeFor;
  final String category;
  final int capacity;
  final int bagId;
  final String bagcode;
  final bool isEmpty;
  final int bagOpen;

  BagTransaction({
    required this.transactionId,
    required this.barcodeFor,
    required this.category,
    required this.capacity,
    required this.bagId,
    required this.bagcode,
    required this.isEmpty,
    required this.bagOpen,
  });

  factory BagTransaction.fromJson(Map<String, dynamic> json) {
    return BagTransaction(
      transactionId: json['TransactionID'] ?? 0,
      barcodeFor: json['BarcodeFor'] ?? '',
      category: json['Category'] ?? '',
      capacity: json['Capacity'] ?? 0,
      bagId: json['BagID'] ?? 0,
      bagcode: json['Bagcode'] ?? '',
      isEmpty: json['IsEmpty'] ?? false,
      bagOpen: json['BagOpen'] ?? 0,
    );
  }
}

class HandoverStatusResponse {
  final String status;
  final String message;

  HandoverStatusResponse({
    required this.status,
    required this.message,
  });

  factory HandoverStatusResponse.fromJson(Map<String, dynamic> json) {
    return HandoverStatusResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
    );
  }

  bool get isSuccess => status.toLowerCase() == 'success';
}