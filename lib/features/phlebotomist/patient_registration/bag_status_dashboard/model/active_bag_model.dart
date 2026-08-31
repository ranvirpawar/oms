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
class PatientRegistrationRecord {
  final String? facilityName;
  final String? fType;
  final String date;
  final String barcode;
  final String patientName;
  final String sampleType;

  PatientRegistrationRecord({
    this.facilityName,
    this.fType,
    required this.date,
    required this.barcode,
    required this.patientName,
    required this.sampleType,
  });

  bool get hasPatientName => patientName.trim().isNotEmpty;
  bool get hasFacility => facilityName != null && facilityName!.trim().isNotEmpty;

  factory PatientRegistrationRecord.fromJson(Map<String, dynamic> json) =>
      PatientRegistrationRecord(
        facilityName: json['FacilityName'],
        fType: json['FType'],
        date: json['date'] ?? '',
        barcode: json['Barcode'] ?? '',
        patientName: json['PatientName'] ?? '',
        sampleType: json['SampleType'] ?? '',
      );
}