// bag_status_model.dart

class BagStatusResponse {
  final String status;
  final String message;
  final List<BagTransaction> output;

  BagStatusResponse({
    required this.status,
    required this.message,
    required this.output,
  });

  factory BagStatusResponse.fromJson(Map<String, dynamic> json) {
    return BagStatusResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      output: (json['output'] as List?)
          ?.map((item) => BagTransaction.fromJson(item))
          .toList() ??
          [],
    );
  }
}

class BagTransaction {
  final String bagcode;
  final int transactionId;
  final int bagId;
  final String currentStage;
  final String creationDatetime;

  BagTransaction({
    required this.bagcode,
    required this.transactionId,
    required this.bagId,
    required this.currentStage,
    required this.creationDatetime,
  });

  factory BagTransaction.fromJson(Map<String, dynamic> json) {
    return BagTransaction(
      bagcode: json['Bagcode'] ?? '',
      transactionId: json['TransactionID'] ?? 0,
      bagId: json['BagID'] ?? 0,
      currentStage: json['CurrentStage'] ?? '',
      creationDatetime: json['Creationdatetime'] ?? '-',
    );
  }

  DateTime? get parsedDateTime {
    if (creationDatetime == '-' || creationDatetime.isEmpty) return null;
    try {
      return DateTime.parse(creationDatetime);
    } catch (e) {
      return null;
    }
  }

  bool get isAvailable => currentStage == 'Available assign';
}

class BagGroup {
  final String bagcode;
  final List<BagTransaction> transactions;

  BagGroup({
    required this.bagcode,
    required this.transactions,
  });

  BagTransaction get latestTransaction => transactions.first;

  bool get isAvailable => latestTransaction.isAvailable;
}