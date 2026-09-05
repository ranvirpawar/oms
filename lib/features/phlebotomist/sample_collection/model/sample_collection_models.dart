// ---------------------------------------------------------------------------
// Tests / special instructions
// ---------------------------------------------------------------------------

class TestInfo {
  final int testId;
  final String testCode;
  final String testName;

  TestInfo({
    required this.testId,
    required this.testCode,
    required this.testName,
  });

  factory TestInfo.fromJson(Map<String, dynamic> json) {
    return TestInfo(
      testId: json['testId'] is int
          ? json['testId'] as int
          : int.tryParse('${json['testId']}') ?? 0,
      testCode: json['testCode'] as String? ?? '',
      testName: json['testName'] as String? ?? '',
    );
  }
}

/// `specialInstructions[]` now comes back as objects, not plain strings.
class SpecialInstruction {
  final int testId;
  final int testSpecialInstId;
  final String instruction;

  SpecialInstruction({
    required this.testId,
    required this.testSpecialInstId,
    required this.instruction,
  });

  factory SpecialInstruction.fromJson(Map<String, dynamic> json) {
    return SpecialInstruction(
      testId: json['testId'] is int
          ? json['testId'] as int
          : int.tryParse('${json['testId']}') ?? 0,
      testSpecialInstId: json['testSpecialInstId'] is int
          ? json['testSpecialInstId'] as int
          : int.tryParse('${json['testSpecialInstId']}') ?? 0,
      instruction: json['specialInstruction'] as String? ?? '',
    );
  }
}

class PatientHeader {
  final String patientId;
  final String name;
  final String age;
  final String gender;
  final String? photoUrl;

  PatientHeader({
    required this.patientId,
    required this.name,
    required this.age,
    required this.gender,
    this.photoUrl,
  });

  factory PatientHeader.fromJson(Map<String, dynamic> json) {
    return PatientHeader(
      patientId: json['patientId']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      age: json['age']?.toString() ?? '',
      gender: json['gender'] as String? ?? '',
      photoUrl: (json['photoUrl'] as String?)?.trim().isNotEmpty == true
          ? json['photoUrl'] as String
          : null,
    );
  }
}

/// A required sample type for the order, now carrying the full list of
/// tests it feeds — needed so the phlebotomist can flag individual tests
/// as unsuitable rather than the whole sample.
class SampleTypeRequirement {
  final int sampleTypeId;
  final String sampleType;
  final String volumeRequiredMl;
  final List<TestInfo> tests;

  SampleTypeRequirement({
    required this.sampleTypeId,
    required this.sampleType,
    required this.volumeRequiredMl,
    required this.tests,
  });

  factory SampleTypeRequirement.fromJson(Map<String, dynamic> json) {
    final testsList = json['tests'];
    return SampleTypeRequirement(
      sampleTypeId: json['sampleTypeId'] is int
          ? json['sampleTypeId'] as int
          : int.tryParse('${json['sampleTypeId']}') ?? 0,
      sampleType: json['sampleType'] as String? ?? '',
      volumeRequiredMl: json['volumeRequiredMl']?.toString() ?? '',
      tests: testsList is List
          ? testsList
          .whereType<Map<String, dynamic>>()
          .map(TestInfo.fromJson)
          .toList()
          : <TestInfo>[],
    );
  }
}

/// Full order confirmation / collection-requirement payload
/// (`output` object from the sample-requirements API).
class OrderConfirmationDetails {
  final String orderId;
  final String priority;
  final String slotDate;
  final String slotStartTime;
  final String slotEndTime;
  final String slotDateTime;
  final PatientHeader patient;
  final String mobileNumber;
  final bool fastingRequired;
  final String? fastingNote;
  final List<SpecialInstruction> specialInstructions;
  final List<SampleTypeRequirement> sampleRequirements;
  final int totalSampleTypes;
  final int totalTestCountReceived;

  OrderConfirmationDetails({
    required this.orderId,
    required this.priority,
    required this.slotDate,
    required this.slotStartTime,
    required this.slotEndTime,
    required this.slotDateTime,
    required this.patient,
    required this.mobileNumber,
    required this.fastingRequired,
    this.fastingNote,
    required this.specialInstructions,
    required this.sampleRequirements,
    required this.totalSampleTypes,
    required this.totalTestCountReceived,
  });

  factory OrderConfirmationDetails.fromJson(Map<String, dynamic> json) {
    final patientJson = json['patient'];
    final specialList = json['specialInstructions'];
    final requirementsList = json['sampleRequirements'];

    return OrderConfirmationDetails(
      orderId: json['orderId']?.toString() ?? '',
      priority: json['priority'] as String? ?? '',
      slotDate: json['slotDate']?.toString() ?? '',
      slotStartTime: json['slotStartTime']?.toString() ?? '',
      slotEndTime: json['slotEndTime']?.toString() ?? '',
      slotDateTime: json['slotDateTime']?.toString() ?? '',
      patient: patientJson is Map<String, dynamic>
          ? PatientHeader.fromJson(patientJson)
          : PatientHeader(patientId: '', name: '', age: '', gender: ''),
      // Note: this comes back as `MobileNumber` (PascalCase), a sibling of
      // `patient`, not a field inside it — matches the sample-requirements
      // response as logged.
      mobileNumber: json['MobileNumber']?.toString() ?? '',
      fastingRequired: json['fastingRequired'] == true,
      fastingNote: json['fastingNote'] as String?,
      specialInstructions: specialList is List
          ? specialList
          .whereType<Map<String, dynamic>>()
          .map(SpecialInstruction.fromJson)
          .toList()
          : <SpecialInstruction>[],
      sampleRequirements: requirementsList is List
          ? requirementsList
          .whereType<Map<String, dynamic>>()
          .map(SampleTypeRequirement.fromJson)
          .toList()
          : <SampleTypeRequirement>[],
      totalSampleTypes: json['totalSampleTypes'] is int
          ? json['totalSampleTypes'] as int
          : int.tryParse('${json['totalSampleTypes']}') ?? 0,
      totalTestCountReceived: json['totalTestCountReceived'] is int
          ? json['totalTestCountReceived'] as int
          : int.tryParse('${json['totalTestCountReceived']}') ?? 0,
    );
  }
}

// ---------------------------------------------------------------------------
// Complications / Incomplete reasons
// ---------------------------------------------------------------------------

class ComplicationOption {
  final int complicationId;
  final String name;

  ComplicationOption({required this.complicationId, required this.name});

  factory ComplicationOption.fromJson(Map<String, dynamic> json) {
    return ComplicationOption(
      complicationId: json['ComplicationID'] is int
          ? json['ComplicationID'] as int
          : int.tryParse('${json['ComplicationID']}') ?? 0,
      name:
      json['ComplicationName'] as String? ?? json['Name'] as String? ?? '',
    );
  }
}

class IncompleteReasonOption {
  final int reasonId;
  final String reason;

  IncompleteReasonOption({required this.reasonId, required this.reason});

  factory IncompleteReasonOption.fromJson(Map<String, dynamic> json) {
    return IncompleteReasonOption(
      reasonId: json['IncompleteReasonID'] is int
          ? json['IncompleteReasonID'] as int
          : int.tryParse('${json['IncompleteReasonID']}') ?? 0,
      reason: json['IncompleteReason'] as String? ?? '',
    );
  }
}

// ---------------------------------------------------------------------------
// Insert-collection payload
// ---------------------------------------------------------------------------

class SampleCollectionDetailEntry {
  final int sampleTypeId;
  final String barcodeNo;

  SampleCollectionDetailEntry({
    required this.sampleTypeId,
    required this.barcodeNo,
  });

  Map<String, dynamic> toJson() => {
    'SampleTypeID': sampleTypeId,
    'BarcodeNo': barcodeNo,
  };
}

class SampleCollectionComplicationEntry {
  final int complicationId;
  final bool status;

  SampleCollectionComplicationEntry({
    required this.complicationId,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
    'ComplicationID': complicationId,
    'Status': status,
  };
}

/// Now test-level: a single sample type can feed several tests, and only
/// some of them may be unsuitable, so we send both IDs.
/// ⚠️ Confirm the backend accepts `TestID` here — the old code's comment
/// said this endpoint only tracked SampleTypeID.
class IncompleteTestEntry {
  final int sampleTypeId;
  final int testId;
  final int incompleteReasonId;
  final String incompleteReason;

  IncompleteTestEntry({
    required this.sampleTypeId,
    required this.testId,
    required this.incompleteReasonId,
    required this.incompleteReason,
  });

  Map<String, dynamic> toJson() => {
    'SampleTypeID': sampleTypeId,
    'TestID': testId,
    'IncompleteReasonID': incompleteReasonId,
    'IncompleteReason': incompleteReason,
  };
}

/// Outcome of a submission attempt, as surfaced to the UI layer.
enum SampleSubmissionOutcome {
  /// Order row inserted AND pushed to LIS successfully.
  success,

  /// The order row was inserted, but the push to LIS failed. The
  /// collector's physical job (drawing + barcoding samples) is done, so
  /// we still show the success screen — just with an outstanding
  /// "sync to Disha" action instead of a hard failure.
  partialLisFailure,
}

class SampleSubmissionResult {
  final SampleSubmissionOutcome outcome;
  final String orderId;
  final String? message;

  const SampleSubmissionResult({
    required this.outcome,
    required this.orderId,
    this.message,
  });

  bool get needsDishaSync =>
      outcome == SampleSubmissionOutcome.partialLisFailure;
}

class SampleCollectionException implements Exception {
  final String message;
  final bool isNetworkError;

  /// True when the backend reports the order was inserted but the push
  /// to LIS failed (status == "Fail Insert Disha"). Treated as a "soft"
  /// success by the controller, not a hard failure that should force the
  /// collector to resubmit the form. Resyncing only needs the orderId —
  /// no extra identifier comes back on this response.
  final bool isLisSyncFailure;

  SampleCollectionException(
      this.message, {
        this.isNetworkError = false,
        this.isLisSyncFailure = false,
      });

  @override
  String toString() => message;
}

class SampleCollectionPayload {
  final String orderId;
  final int userId;
  final String orderStatusCode;
  final int bagId;
  final int tubeCount;

  final int sessionId;
  final String notes;
  final DateTime collectedAt;
  final List<SampleCollectionDetailEntry> sampleCollectionDetails;
  final List<SampleCollectionComplicationEntry> sampleCollectionComplications;
  final List<IncompleteTestEntry> incompleteTests;

  SampleCollectionPayload({
    required this.orderId,
    required this.userId,
    required this.orderStatusCode,
    required this.bagId,
    required this.sessionId,
    required this.tubeCount,
    required this.notes,
    required this.collectedAt,
    required this.sampleCollectionDetails,
    required this.sampleCollectionComplications,
    required this.incompleteTests,
  });

  Map<String, dynamic> toJson() => {
    'OrderID': orderId,
    'UserID': userId,
    'OrderStatusCode': orderStatusCode,
    'bagId': bagId,
    'SessionID': sessionId,
    'TubeCount' : tubeCount,
    'Notes': notes,
    'CollectedAt': collectedAt.toUtc().toIso8601String(),
    'SampleCollectionDetails':
    sampleCollectionDetails.map((e) => e.toJson()).toList(),
    'SampleCollectionComplications':
    sampleCollectionComplications.map((e) => e.toJson()).toList(),
    'IncompleteTests': incompleteTests.map((e) => e.toJson()).toList(),
  };
}