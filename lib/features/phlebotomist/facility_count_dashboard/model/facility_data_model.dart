// Model classes
class FacilityData {
  final String facilityName;
  final String facilityId;
  final int? trfP;
  final int? tubeCountP;
  final int totalRegistrationPatient;
  final int? trfR;
  final int? tubeCountR;
  final int? trfCountL;
  final int? tubeCountL;

  FacilityData({
    required this.facilityName,
    required this.facilityId,
    this.trfP,
    this.tubeCountP,
    required this.totalRegistrationPatient,
    this.trfR,
    this.tubeCountR,
    this.trfCountL,
    this.tubeCountL,
  });

  factory FacilityData.fromJson(Map<String, dynamic> json) {
    return FacilityData(
      facilityName: json['Facilityname'] ?? '',
      facilityId: json['FacilityID'] ?? '',
      trfP: json['TRF_P'],
      tubeCountP: json['Tubecount_P'],
      totalRegistrationPatient: json['TotalRegsitrationPatient'] ?? 0,
      trfR: json['TRF_R'],
      tubeCountR: json['Tubecount_R'],
      trfCountL: json['TRFcount_L'],
      tubeCountL: json['Tubecount_L'],
    );
  }
}