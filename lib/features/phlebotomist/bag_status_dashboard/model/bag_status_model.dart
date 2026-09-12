// models/scan_qr_model.dart
class ScanQRModel {
  final String status;
  final String message;
  final List<ScanQROutput>? output;

  ScanQRModel({
    required this.status,
    required this.message,
    this.output,
  });

  factory ScanQRModel.fromJson(Map<String, dynamic> json) {
    return ScanQRModel(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      output: json['output'] != null
          ? (json['output'] as List)
          .map((e) => ScanQROutput.fromJson(e))
          .toList()
          : null,
    );
  }
}

class ScanQROutput {
  final int transactionID;
  final String barcodeFor;
  final String category;
  final int capacity;
  final int bagID;
  final String bagcode;
  final bool isEmpty;
  final int bagOpen;

  ScanQROutput({
    required this.transactionID,
    required this.barcodeFor,
    required this.category,
    required this.capacity,
    required this.bagID,
    required this.bagcode,
    required this.isEmpty,
    required this.bagOpen,
  });

  factory ScanQROutput.fromJson(Map<String, dynamic> json) {
    return ScanQROutput(
      transactionID: json['TransactionID'] ?? 0,
      barcodeFor: json['BarcodeFor'] ?? '',
      category: json['Category'] ?? '',
      capacity: json['Capacity'] ?? 0,
      bagID: json['BagID'] ?? 0,
      bagcode: json['Bagcode'] ?? '',
      isEmpty: json['IsEmpty'] ?? false,
      bagOpen: json['BagOpen'] ?? 0,
    );
  }
}