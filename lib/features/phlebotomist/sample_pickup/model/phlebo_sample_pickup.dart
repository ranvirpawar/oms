class FacilityResponse {
  final String status;
  final String message;
  final List<PhleboSamplePickup> output;

  FacilityResponse({
    required this.status,
    required this.message,
    required this.output,
  });

  factory FacilityResponse.fromJson(Map<String, dynamic> json) {
    return FacilityResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      output: (json['output'] as List<dynamic>)
          .map((item) => PhleboSamplePickup.fromJson(item))
          .toList(),
    );
  }
}

class PhleboSamplePickup {
  final String? phleboName;
  final String? phleboMobNo;
  final int? centerId;
  final int? labcode;
  final int? facilityCode;
  final String? facilityName;
  final String? cptCode;
  final int? fType;
  final double? distance;
  final String? area;
  final String? city;
  final int? creationUid;
  final String? creationDateTime;
  final int? modifyUid;
  final String? modifyDateTime;
  final String? mobile;
  final String? email;
  final String? barcodeCode;
  final String? lastGenerateDate;
  final String? barcodeGap;
  final String? active;
  final String? distanceFromLaboratory;
  final String? labChangeDate;
  final String? isActive;
  final String? cdacLabcode;
  final String? cdacHospitalCode;
  final String? ward;
  final String? subtype;
  final String? clinicAddress;
  final int? sampleCount;
  final int? trfP;

  PhleboSamplePickup({
    this.phleboName,
    this.phleboMobNo,
    this.centerId,
    this.labcode,
    this.facilityCode,
    this.facilityName,
    this.cptCode,
    this.fType,
    this.distance,
    this.area,
    this.city,
    this.creationUid,
    this.creationDateTime,
    this.modifyUid,
    this.modifyDateTime,
    this.mobile,
    this.email,
    this.barcodeCode,
    this.lastGenerateDate,
    this.barcodeGap,
    this.active,
    this.distanceFromLaboratory,
    this.labChangeDate,
    this.isActive,
    this.cdacLabcode,
    this.cdacHospitalCode,
    this.ward,
    this.subtype,
    this.clinicAddress,
    this.sampleCount,
    this.trfP,
  });

  factory PhleboSamplePickup.fromJson(Map<String, dynamic> json) {
    return PhleboSamplePickup(
      phleboName: json['PhleboName'],
      phleboMobNo: json['PhleboMobNo'],
      centerId: json['CenterID'],
      labcode: json['Labcode'],
      facilityCode: json['FacilityCode'],
      facilityName: json['FacilityName'],
      cptCode: json['CPTCode'],
      fType: json['FType'],
      distance: (json['Distance'] != null)
          ? double.tryParse(json['Distance'].toString())
          : null,
      area: json['Area'],
      city: json['City'],
      creationUid: json['CreationUID'],
      creationDateTime: json['CreationDateTime'],
      modifyUid: json['ModifyUID'],
      modifyDateTime: json['ModifyDateTime'],
      mobile: json['Mobile'],
      email: json['Email'],
      barcodeCode: json['BarcodeCode'],
      lastGenerateDate: json['LastGenerateDate'],
      barcodeGap: json['BarcodeGap'],
      active: json['Active'],
      distanceFromLaboratory: json['Distance_from_Laboratory'],
      labChangeDate: json['LabChangeDate'],
      isActive: json['ISACTIVE'],
      cdacLabcode: json['CDACLabcode'],
      cdacHospitalCode: json['CDAC_HospitalCode'],
      ward: json['WARD'],
      subtype: json['SUBTYPE'],
      clinicAddress: json['ClinicAddress'],
      sampleCount: json['Samplecount'],
      trfP: json['TRF_P'],
    );
  }
}
