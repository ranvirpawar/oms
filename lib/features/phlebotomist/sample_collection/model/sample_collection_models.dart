// sample_collection_models.dart
//
// Models for the Sample Collection module. Mirrors the app's existing
// pattern (simple fromJson factories, defensive parsing, no codegen).

// ---------------------------------------------------------------------------
// Order Confirmation / header
// ---------------------------------------------------------------------------

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

/// A required sample type for the order, as returned by the API
/// (`sampleRequirements[]` inside `output`).
class SampleTypeRequirement {
  final int sampleTypeId;
  final String sampleType;
  final String volumeRequiredMl;

  SampleTypeRequirement({
    required this.sampleTypeId,
    required this.sampleType,
    required this.volumeRequiredMl,
  });

  factory SampleTypeRequirement.fromJson(Map<String, dynamic> json) {
    return SampleTypeRequirement(
      sampleTypeId: json['sampleTypeId'] is int
          ? json['sampleTypeId'] as int
          : int.tryParse('${json['sampleTypeId']}') ?? 0,
      sampleType: json['sampleType'] as String? ?? '',
      volumeRequiredMl: json['volumeRequiredMl']?.toString() ?? '',
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
  final bool fastingRequired;
  final String? fastingNote;
  final List<String> specialInstructions;
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
      fastingRequired: json['fastingRequired'] == true,
      fastingNote: json['fastingNote'] as String?,
      specialInstructions: specialList is List
          ? specialList.map((e) => e.toString()).toList()
          : <String>[],
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

/// A reason a sample could not be collected.
class IncompleteReasonOption {
  final int reasonId;
  final String reason;

  IncompleteReasonOption({required this.reasonId, required this.reason});

  factory IncompleteReasonOption.fromJson(Map<String, dynamic> json) {
    return IncompleteReasonOption(
      reasonId: json['IncompleteReasonID'] is int
          ? json['IncompleteReasonID'] as int
          : int.tryParse('${json['IncompleteReasonID']}') ?? 0,
      reason: json['Reason'] as String? ?? '',
    );
  }
}

// ---------------------------------------------------------------------------
// Insert-collection payload (request body for submitSampleCollection)
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

/// Note: partial collection is tracked by SampleTypeID (not TestID) per the
/// backend contract, since a single test can map to multiple sample types
/// and collection happens at the sample-type level.
class IncompleteTestEntry {
  final int sampleTypeId;
  final int incompleteReasonId;
  final String incompleteReason;

  IncompleteTestEntry({
    required this.sampleTypeId,
    required this.incompleteReasonId,
    required this.incompleteReason,
  });

  Map<String, dynamic> toJson() => {
        'SampleTypeID': sampleTypeId,
        'IncompleteReasonID': incompleteReasonId,
        'IncompleteReason': incompleteReason,
      };
}

class SampleCollectionPayload {
  final String orderId;
  final int userId;
  final String orderStatusCode;
  final String bagId;
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
        'Notes': notes,
        'CollectedAt': collectedAt.toUtc().toIso8601String(),
        'SampleCollectionDetails':
            sampleCollectionDetails.map((e) => e.toJson()).toList(),
        'SampleCollectionComplications':
            sampleCollectionComplications.map((e) => e.toJson()).toList(),
        'IncompleteTests': incompleteTests.map((e) => e.toJson()).toList(),
      };
}
