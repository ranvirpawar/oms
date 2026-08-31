// models/collect_bag_model.dart

class BagScanResponse {
  final String status;
  final String message;
  final List<BagDetail> output;

  BagScanResponse({
    required this.status,
    required this.message,
    required this.output,
  });

  factory BagScanResponse.fromJson(Map<String, dynamic> json) {
    return BagScanResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      output: (json['output'] as List?)
          ?.map((e) => BagDetail.fromJson(e))
          .toList() ??
          [],
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

class TransactionStatusResponse {
  final String status;
  final String message;

  TransactionStatusResponse({
    required this.status,
    required this.message,
  });

  factory TransactionStatusResponse.fromJson(Map<String, dynamic> json) {
    return TransactionStatusResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
    );
  }
}

enum OperationType {
  collectBag,
  transferBag,
}

extension OperationTypeExtension on OperationType {
  String get displayName {
    switch (this) {
      case OperationType.collectBag:
        return 'Collect Bag';
      case OperationType.transferBag:
        return 'Transfer Bag';
    }
  }
}