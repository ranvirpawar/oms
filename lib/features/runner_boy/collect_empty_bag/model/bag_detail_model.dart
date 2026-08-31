// models/bag_model_new.dart

class BagDetailsResponse {
  final String status;
  final String message;
  final List<BagDetail>? output;

  BagDetailsResponse({
    required this.status,
    required this.message,
    this.output,
  });

  factory BagDetailsResponse.fromJson(Map<String, dynamic> json) {
    return BagDetailsResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      output: json['output'] != null
          ? (json['output'] as List)
          .map((item) => BagDetail.fromJson(item))
          .toList()
          : null,
    );
  }

  bool get isSuccess => status.toLowerCase() == 'success';
}

class BagDetail {
  final String barcodeFor;
  final String category;
  final int capacity;
  final int bagId;
  final String bagcode;

  BagDetail({
    required this.barcodeFor,
    required this.category,
    required this.capacity,
    required this.bagId,
    required this.bagcode,
  });

  factory BagDetail.fromJson(Map<String, dynamic> json) {
    return BagDetail(
      barcodeFor: json['BarcodeFor'] ?? '',
      category: json['Category'] ?? '',
      capacity: json['Capacity'] ?? 0,
      bagId: json['BagID'] ?? 0,
      bagcode: json['Bagcode'] ?? '',
    );
  }
}

class BagTransactionResponse {
  final String status;
  final int? transactionId;
  final String message;

  BagTransactionResponse({
    required this.status,
    this.transactionId,
    required this.message,
  });

  factory BagTransactionResponse.fromJson(Map<String, dynamic> json) {
    return BagTransactionResponse(
      status: json['status'] ?? '',
      transactionId: json['transactionid'],
      message: json['message'] ?? '',
    );
  }

  bool get isSuccess => status.toLowerCase() == 'success';
}

class BagStatusResponse {
  final String status;
  final String message;

  BagStatusResponse({
    required this.status,
    required this.message,
  });

  factory BagStatusResponse.fromJson(Map<String, dynamic> json) {
    return BagStatusResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
    );
  }

  bool get isSuccess => status.toLowerCase() == 'success';
}