// accept_bag_model.dart

class AssignedBag {
  final int transactionId;
  final int bagId;
  final String bagcode;
  final int userId;
  final String phleboName;
  final int transitionStatus;
  final String createdOn;

  AssignedBag({
    required this.transactionId,
    required this.bagId,
    required this.bagcode,
    required this.userId,
    required this.phleboName,
    required this.transitionStatus,
    required this.createdOn,
  });

  factory AssignedBag.fromJson(Map<String, dynamic> json) {
    return AssignedBag(
      transactionId: json['TransactionID'] ?? 0,
      bagId: json['BagID'] ?? 0,
      bagcode: json['Bagcode'] ?? '',
      userId: json['USERID'] ?? 0,
      phleboName: json['PhleboName'] ?? '',
      transitionStatus: json['TransitionStatus'] ?? 0,
      createdOn: json['CreatedOn'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'TransactionID': transactionId,
      'BagID': bagId,
      'Bagcode': bagcode,
      'USERID': userId,
      'PhleboName': phleboName,
      'TransitionStatus': transitionStatus,
      'CreatedOn': createdOn,
    };
  }

  // Parse date from /Date(timestamp)/
  DateTime? get parsedDate {
    try {
      final regex = RegExp(r'\/Date\((\d+)\)\/');
      final match = regex.firstMatch(createdOn);
      if (match != null) {
        final timestamp = int.parse(match.group(1)!);
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  String get formattedDate {
    final date = parsedDate;
    if (date != null) {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
    return 'N/A';
  }

  String get formattedDateTime {
    final date = parsedDate;
    if (date != null) {
      final hour = date.hour > 12 ? date.hour - 12 : date.hour;
      final amPm = date.hour >= 12 ? 'PM' : 'AM';
      return '${date.day}/${date.month}/${date.year} ${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $amPm';
    }
    return 'N/A';
  }
}

class AssignedBagListResponse {
  final String status;
  final String message;
  final List<AssignedBag>? output;

  AssignedBagListResponse({
    required this.status,
    required this.message,
    this.output,
  });

  bool get isSuccess => status.toLowerCase() == 'success';

  factory AssignedBagListResponse.fromJson(Map<String, dynamic> json) {
    return AssignedBagListResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      output: json['output'] != null
          ? (json['output'] as List)
              .map((item) => AssignedBag.fromJson(item))
              .toList()
          : null,
    );
  }
}

class BagQRTransaction {
  final int transactionId;
  final String barcodeFor;
  final String category;
  final int capacity;
  final int bagId;
  final String bagcode;
  final bool isEmpty;
  final int bagOpen;

  BagQRTransaction({
    required this.transactionId,
    required this.barcodeFor,
    required this.category,
    required this.capacity,
    required this.bagId,
    required this.bagcode,
    required this.isEmpty,
    required this.bagOpen,
  });

  factory BagQRTransaction.fromJson(Map<String, dynamic> json) {
    return BagQRTransaction(
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

  Map<String, dynamic> toJson() {
    return {
      'TransactionID': transactionId,
      'BarcodeFor': barcodeFor,
      'Category': category,
      'Capacity': capacity,
      'BagID': bagId,
      'Bagcode': bagcode,
      'IsEmpty': isEmpty,
      'BagOpen': bagOpen,
    };
  }
}

class BagQRTransactionResponse {
  final String status;
  final String message;
  final List<BagQRTransaction>? output;

  BagQRTransactionResponse({
    required this.status,
    required this.message,
    this.output,
  });

  bool get isSuccess => status.toLowerCase() == 'success';

  factory BagQRTransactionResponse.fromJson(Map<String, dynamic> json) {
    return BagQRTransactionResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      output: json['output'] != null
          ? (json['output'] as List)
              .map((item) => BagQRTransaction.fromJson(item))
              .toList()
          : null,
    );
  }
}

class AcceptBagResponse {
  final String status;
  final String message;

  AcceptBagResponse({
    required this.status,
    required this.message,
  });

  bool get isSuccess => status.toLowerCase() == 'success';

  factory AcceptBagResponse.fromJson(Map<String, dynamic> json) {
    return AcceptBagResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
    );
  }
}

enum AcceptBagState {
  idle,
  loading,
  scanning,
  processing,
  success,
  error,
}
