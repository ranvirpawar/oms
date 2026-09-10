// collected_bag_model.dart
// ─────────────────────────────────────────────
// MODELS
// ─────────────────────────────────────────────

class QRBag {
  final int sessionId;
  final int bagId;
  final String bagcode;
  final String collectedDate;   // still keep for display if needed
  final DateTime collectedAt;   // now uses the real timestamp
  final String status;
  final int tubeCount;
  final String facilityName;
  final DateTime createdAt;

  QRBag({
    required this.sessionId,
    required this.bagId,
    required this.bagcode,
    required this.collectedDate,
    required this.collectedAt,
    required this.status,
    required this.tubeCount,
    required this.facilityName,
    required this.createdAt,
  });

  factory QRBag.fromJson(Map<String, dynamic> json) {
    final DateTime createdAt = _parseDateTime(json['Createdon']);

    // Prefer Createdon (has time). Fall back to Collecteddate only if Createdon is missing.
    final DateTime collectedAt = _parseDateTime(
      json['Createdon'],
      fallback: _parseDateTime(json['Collecteddate']),
    );

    return QRBag(
      sessionId: json['SessionID'] ?? 0,
      bagId: json['BagID'] ?? 0,
      bagcode: json['Bagcode']?.toString() ?? '',
      collectedDate: json['Collecteddate']?.toString() ?? '',
      collectedAt: collectedAt,
      status: json['Status']?.toString() ?? '',
      tubeCount: json['Tubecount'] ?? 0,
      facilityName: json['FacilityName']?.toString() ?? '—',
      createdAt: createdAt,
    );
  }

  static DateTime _parseDateTime(dynamic value, {DateTime? fallback}) {
    if (value == null) return fallback ?? DateTime.now();

    try {
      if (value is DateTime) return value;
      return DateTime.parse(value.toString());
    } catch (_) {
      return fallback ?? DateTime.now();
    }
  }
}

class QRBagListResponse {
  final bool isSuccess;
  final String message;
  final List<QRBag>? output;

  QRBagListResponse({
    required this.isSuccess,
    required this.message,
    this.output,
  });

  factory QRBagListResponse.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString().toLowerCase();
    final isSuccess = status == 'success' || status == '1' || status == 'true';
    List<QRBag>? bags;
    if (json['output'] != null && json['output'] is List) {
      bags = (json['output'] as List)
          .map((e) => QRBag.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return QRBagListResponse(
      isSuccess: isSuccess,
      message: json['message']?.toString() ?? '',
      output: bags,
    );
  }
}
class CollectedBag {
  final int transactionId;
  final int bagId;
  final String bagcode;
  final int facilitycode;
  final String facilityName;
  final String fType;
  final String ward;
  final String collectionDate;
  final String labSubmissionStatus;

  CollectedBag({
    required this.transactionId,
    required this.bagId,
    required this.bagcode,
    required this.facilitycode,
    required this.facilityName,
    required this.fType,
    required this.ward,
    required this.collectionDate,
    required this.labSubmissionStatus,
  });

  factory CollectedBag.fromJson(Map<String, dynamic> json) {
    return CollectedBag(
      transactionId: json['TransactionID'] ?? 0,
      bagId: json['BagID'] ?? 0,
      bagcode: json['Bagcode'] ?? '',
      facilitycode: json['Facilitycode'] ?? 0,
      facilityName: json['FacilityName'] ?? '',
      fType: json['FType'] ?? '',
      ward: json['Ward'] ?? '',
      collectionDate: json['CollectionDate'] ?? '',
      labSubmissionStatus: json['LabSubmissionStatus'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'TransactionID': transactionId,
      'BagID': bagId,
      'Bagcode': bagcode,
      'Facilitycode': facilitycode,
      'FacilityName': facilityName,
      'FType': fType,
      'Ward': ward,
      'CollectionDate': collectionDate,
      'LabSubmissionStatus': labSubmissionStatus,
    };
  }
}

class CollectedBagListResponse {
  final String status;
  final String message;
  final List<CollectedBag>? output;

  CollectedBagListResponse({
    required this.status,
    required this.message,
    this.output,
  });

  bool get isSuccess => status.toLowerCase() == 'success';

  factory CollectedBagListResponse.fromJson(Map<String, dynamic> json) {
    return CollectedBagListResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      output: json['output'] != null
          ? (json['output'] as List)
          .map((item) => CollectedBag.fromJson(item))
          .toList()
          : null,
    );
  }
}

class LabSubmissionResponse {
  final String status;
  final String message;

  LabSubmissionResponse({
    required this.status,
    required this.message,
  });

  bool get isSuccess => status.toLowerCase() == 'success';

  factory LabSubmissionResponse.fromJson(Map<String, dynamic> json) {
    return LabSubmissionResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
    );
  }
}

