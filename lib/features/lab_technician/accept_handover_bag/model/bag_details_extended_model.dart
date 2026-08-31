// ─── bag_details_extended_model.dart ─────────────────────────────────────────
// Models for the two additional bag-detail API calls:
//   type=2 → facility summary list
//   type=4 → patient registration list

// ─── Type 2: Facility Summary ─────────────────────────────────────────────────

class BagFacilityItem {
  final String ward;
  final int facilityCode;
  final String facilityName;
  final String fType;
  final int tubeCount;
  final String? sampleTransferDatetime;

  const BagFacilityItem({
    required this.ward,
    required this.facilityCode,
    required this.facilityName,
    required this.fType,
    required this.tubeCount,
    this.sampleTransferDatetime,
  });

  factory BagFacilityItem.fromJson(Map<String, dynamic> json) {
    return BagFacilityItem(
      ward: json['Ward']?.toString() ?? '',
      facilityCode: (json['Facilitycode'] as num?)?.toInt() ?? 0,
      facilityName: json['FacilityName']?.toString() ?? '',
      fType: json['FType']?.toString() ?? '',
      tubeCount: (json['Tubecount'] as num?)?.toInt() ?? 0,
      sampleTransferDatetime: json['Sampletransferdatetime']?.toString(),
    );
  }
}

class BagFacilityListResponse {
  final String status;
  final String message;
  final List<BagFacilityItem>? output;

  const BagFacilityListResponse({
    required this.status,
    required this.message,
    this.output,
  });

  factory BagFacilityListResponse.fromJson(Map<String, dynamic> json) {
    final rawOutput = json['output'];
    List<BagFacilityItem>? items;
    if (rawOutput is List) {
      items = rawOutput
          .whereType<Map<String, dynamic>>()
          .map((e) => BagFacilityItem.fromJson(e))
          .toList();
    }
    return BagFacilityListResponse(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      output: items,
    );
  }
}

// ─── Type 4: Patient Registration List ───────────────────────────────────────

class BagPatientItem {
  final String ward;
  final String facilityName;
  final String fType;
  final String patientName;
  final String orderNo;
  final String sampleCollectionTime;
  final String? sampleTransferDatetime;

  const BagPatientItem({
    required this.ward,
    required this.facilityName,
    required this.fType,
    required this.patientName,
    required this.orderNo,
    required this.sampleCollectionTime,
    this.sampleTransferDatetime,
  });

  factory BagPatientItem.fromJson(Map<String, dynamic> json) {
    return BagPatientItem(
      ward: json['Ward']?.toString() ?? '',
      facilityName: json['FacilityName']?.toString() ?? '',
      fType: json['FType']?.toString() ?? '',
      patientName: json['PatientName']?.toString() ?? '',
      orderNo: json['orderno']?.toString() ?? '',
      sampleCollectionTime: json['SamplecollectionTime']?.toString() ?? '',
      sampleTransferDatetime: json['Sampletransferdatetime']?.toString(),
    );
  }
}

class BagPatientListResponse {
  final String status;
  final String message;
  final List<BagPatientItem>? output;

  const BagPatientListResponse({
    required this.status,
    required this.message,
    this.output,
  });

  factory BagPatientListResponse.fromJson(Map<String, dynamic> json) {
    final rawOutput = json['output'];
    List<BagPatientItem>? items;
    if (rawOutput is List) {
      items = rawOutput
          .whereType<Map<String, dynamic>>()
          .map((e) => BagPatientItem.fromJson(e))
          .toList();
    }
    return BagPatientListResponse(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      output: items,
    );
  }
}