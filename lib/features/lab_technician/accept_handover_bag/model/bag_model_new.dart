// lib/features/lab_technician/accept_bag_in_lab/model/bag_model_new.dart

// ─── Step 1: /GETScanQRBag response ───────────────────────────────────────────

class ScanQRBagResponse {
  final String status;
  final String message;
  final List<ScanQRBagOutput>? output;

  ScanQRBagResponse({
    required this.status,
    required this.message,
    this.output,
  });

  factory ScanQRBagResponse.fromJson(Map<String, dynamic> json) {
    return ScanQRBagResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      output: json['output'] != null
          ? (json['output'] as List)
              .map((e) => ScanQRBagOutput.fromJson(e))
              .toList()
          : null,
    );
  }
}

class ScanQRBagOutput {
  final int sessionID;
  final int bagid;
  final String ward;
  final String fType;
  final String asFacilityName;
  final int tubecount;

  ScanQRBagOutput({
    required this.sessionID,
    required this.bagid,
    required this.ward,
    required this.fType,
    required this.asFacilityName,
    required this.tubecount,
  });

  factory ScanQRBagOutput.fromJson(Map<String, dynamic> json) {
    return ScanQRBagOutput(
      sessionID: json['SessionID'] ?? 0,
      bagid: json['Bagid'] ?? 0,
      ward: json['Ward'] ?? '',
      fType: json['FType'] ?? '',
      asFacilityName: json['asFacilityName'] ?? '',
      tubecount: json['Tubecount'] ?? 0,
    );
  }
}

// ─── Step 2: /Proc_GetQRBagDetails_ForLabTeam response ────────────────────────
// NOTE: Response structure is a placeholder — update once real response is known.
class BagDetailsForLabResponse {
  final String status;
  final String message;
  final BagDetailsForLabOutput? output;

  BagDetailsForLabResponse({
    required this.status,
    required this.message,
    this.output,
  });

  factory BagDetailsForLabResponse.fromJson(Map<String, dynamic> json) {
    final rawOutput = json['output'];
    BagDetailsForLabOutput? output;

    if (rawOutput is List && rawOutput.isNotEmpty) {
      output = BagDetailsForLabOutput.fromJson(
          rawOutput.first as Map<String, dynamic>);
    }

    return BagDetailsForLabResponse(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      output: output,
    );
  }
}

class BagDetailsForLabOutput {
  final int sessionID;
  final String bagQRCode;

  // Submitted by
  final String bagSubmittedBy;
  final String bagSubmittedByDesignation;
  final String bagSubmittedByMobile;

  // Transferred by (nullable)
  final String? bagTransferredBy;
  final String? bagTransferredDesignation;
  final String? bagTransferredMobile;

  // Others
  final int? tubeCount;
  final String acceptedBy;
  final String acceptedOn;

  BagDetailsForLabOutput({
    required this.sessionID,
    required this.bagQRCode,
    required this.bagSubmittedBy,
    required this.bagSubmittedByDesignation,
    required this.bagSubmittedByMobile,
    this.bagTransferredBy,
    this.bagTransferredDesignation,
    this.bagTransferredMobile,
    this.tubeCount,
    required this.acceptedBy,
    required this.acceptedOn,
  });

  factory BagDetailsForLabOutput.fromJson(Map<String, dynamic> json) {
    return BagDetailsForLabOutput(
      sessionID: json['SessionID'] as int? ?? 0,
      bagQRCode: json['BagQRCode']?.toString() ?? '',
      bagSubmittedBy: json['BagSubmittedby']?.toString() ?? '',
      bagSubmittedByDesignation:
      json['BagSubmittedby_Designation']?.toString() ?? '',
      bagSubmittedByMobile:
      json['BagSubmittedby_Mobilenumber']?.toString() ?? '',
      bagTransferredBy: json['BagTransferedby']?.toString(),
      bagTransferredDesignation:
      json['BagTransfered_Designation']?.toString(),
      bagTransferredMobile:
      json['BagTransfered_Mobilenumber']?.toString(),
      tubeCount: json['Tubecount'] as int?,
      acceptedBy: json['Acceptedby']?.toString() ?? '',
      acceptedOn: json['accepetdon']?.toString() ?? '',
    );
  }
}

// ─── Step 3: /InsertQRBagSession_Event response ───────────────────────────────

class BagSessionEventResponse {
  final String status;
  final String message;

  BagSessionEventResponse({
    required this.status,
    required this.message,
  });

  factory BagSessionEventResponse.fromJson(Map<String, dynamic> json) {
    return BagSessionEventResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
    );
  }
}
