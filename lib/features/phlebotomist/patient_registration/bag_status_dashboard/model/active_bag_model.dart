// Active bag session from GetActiveQRBagSessions
class ActiveBagSession {
  final int sessionID;
  final int bagId;
  final String bagcode;

  ActiveBagSession({
    required this.sessionID,
    required this.bagId,
    required this.bagcode,
  });

  factory ActiveBagSession.fromJson(Map<String, dynamic> json) => ActiveBagSession(
    sessionID: json['SessionID'] ?? 0,
    bagId: json['BagID'] ?? 0,
    bagcode: json['Bagcode'] ?? '',
  );

  // For dropdown display
  String get displayLabel => 'Bag: $bagcode';
}

// Patient registration record
class RegistrationDetails {
  final int sampleCollectionOrderID;
  final int sessionID;
  final int bagid;
  final String patientName;
  final String gender;
  final String age;
  final String visitType;
  final String address;
  final String mobileNumber;
  final String clinicName;
  final DateTime? collectionDateTime;

  RegistrationDetails({
    required this.sampleCollectionOrderID,
    required this.sessionID,
    required this.bagid,
    required this.patientName,
    required this.gender,
    required this.age,
    required this.visitType,
    required this.address,
    required this.mobileNumber,
    required this.clinicName,
    required this.collectionDateTime,
  });

  factory RegistrationDetails.fromJson(Map<String, dynamic> json) {
    return RegistrationDetails(
      sampleCollectionOrderID: json['SampleCollectionOrderID'] ?? 0,
      sessionID: json['SessionID'] ?? 0,
      bagid: json['Bagid'] ?? 0,
      patientName: (json['PatientName'] ?? '').toString(),
      gender: (json['Gender'] ?? '').toString(),
      age: (json['Age'] ?? '').toString(),
      visitType: (json['VisitType'] ?? '').toString(),
      address: (json['Address'] ?? '').toString(),
      mobileNumber: (json['MobileNumber'] ?? '').toString(),
      clinicName: (json['ClinicName'] ?? '').toString(),
      collectionDateTime: DateTime.tryParse(json['CollectionDateTime'] ?? ''),
    );
  }
}

class TestDetail {
  final int sampleCollectionOrderID;
  final String testName;
  final String sampleTypeName;
  final String tubeContent;

  TestDetail({
    required this.sampleCollectionOrderID,
    required this.testName,
    required this.sampleTypeName,
    required this.tubeContent,
  });

  factory TestDetail.fromJson(Map<String, dynamic> json) => TestDetail(
    sampleCollectionOrderID: json['SampleCollectionOrderID'] ?? 0,
    testName: (json['TestName'] ?? '').toString(),
    sampleTypeName: (json['SampleTypeName'] ?? '').toString(),
    tubeContent: (json['TubeContent'] ?? '').toString(),
  );
}

class BarcodeDetail {
  final int sampleCollectionOrderID;
  final String barcodeNo;

  BarcodeDetail({required this.sampleCollectionOrderID, required this.barcodeNo});

  factory BarcodeDetail.fromJson(Map<String, dynamic> json) => BarcodeDetail(
    sampleCollectionOrderID: json['SampleCollectionOrderID'] ?? 0,
    barcodeNo: (json['BarcodeNo'] ?? '').toString(),
  );
}

/// One card == one patient's full order: registration info + all its tests + all its barcodes.
class PatientOrder {
  final RegistrationDetails registration;
  final List<TestDetail> tests;
  final List<BarcodeDetail> barcodes;

  PatientOrder({
    required this.registration,
    required this.tests,
    required this.barcodes,
  });

  /// Creates PatientOrder objects by grouping:
  /// registrationDetails + testDetails + barcodeDetails
  /// using SampleCollectionOrderID.
  static List<PatientOrder> fromResponse(Map<String, dynamic> json) {
    final registrations =
        (json['registrationDetails'] as List?)
            ?.map(
              (e) => RegistrationDetails.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
            .toList() ??
            [];

    final tests =
        (json['testDetails'] as List?)
            ?.map(
              (e) => TestDetail.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
            .toList() ??
            [];

    final barcodes =
        (json['barcodeDetails'] as List?)
            ?.map(
              (e) => BarcodeDetail.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
            .toList() ??
            [];

    // Group tests by SampleCollectionOrderID
    final testsByOrderId = <int, List<TestDetail>>{};

    for (final test in tests) {
      testsByOrderId.putIfAbsent(
        test.sampleCollectionOrderID,
            () => [],
      ).add(test);
    }

    // Group barcodes by SampleCollectionOrderID
    final barcodesByOrderId = <int, List<BarcodeDetail>>{};

    for (final barcode in barcodes) {
      barcodesByOrderId.putIfAbsent(
        barcode.sampleCollectionOrderID,
            () => [],
      ).add(barcode);
    }

    // Create one PatientOrder for each registration/order
    return registrations.map((registration) {
      final orderId = registration.sampleCollectionOrderID;

      return PatientOrder(
        registration: registration,
        tests: testsByOrderId[orderId] ?? [],
        barcodes: barcodesByOrderId[orderId] ?? [],
      );
    }).toList();
  }

  bool get hasPatientName =>
      registration.patientName.trim().isNotEmpty;

  String get testNamesJoined =>
      tests
          .map((t) => t.testName)
          .where((n) => n.isNotEmpty)
          .join(', ');

  String get primaryBarcode =>
      barcodes.isNotEmpty ? barcodes.first.barcodeNo : '';

  bool matchesQuery(String lowerQuery) {
    if (registration.patientName
        .toLowerCase()
        .contains(lowerQuery)) {
      return true;
    }

    return barcodes.any(
          (b) => b.barcodeNo.toLowerCase().contains(lowerQuery),
    );
  }

  String get tubesSummary {
    final counts = <String, int>{};

    for (final t in tests) {
      final label = _shortTubeLabel(t.tubeContent);

      if (label.isEmpty) continue;

      counts[label] = (counts[label] ?? 0) + 1;
    }

    return counts.entries
        .map((e) => '${e.value} ${e.key}')
        .join(', ');
  }

  static String _shortTubeLabel(String tubeContent) {
    final lower = tubeContent.toLowerCase();

    if (lower.contains('edta')) return 'EDTA';
    if (lower.contains('serum separat') ||
        lower.contains('sst')) {
      return 'SST';
    }
    if (lower.contains('sodium fluoride') ||
        lower.contains('naf')) {
      return 'NaF';
    }
    if (lower.contains('citrate')) return 'Citrate';
    if (lower.contains('heparin')) return 'Heparin';
    if (lower.contains('plain')) return 'Plain';

    return tubeContent;
  }
}