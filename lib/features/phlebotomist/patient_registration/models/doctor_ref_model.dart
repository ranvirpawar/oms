class ReferenceDoctor {
  final int refDocCode;
  final String refDoctorName;
  final int facilityCode;
  final String facilityName;
  final DateTime? visitDate;

  ReferenceDoctor({
    required this.refDocCode,
    required this.refDoctorName,
    required this.facilityCode,
    required this.facilityName,
     this.visitDate,
  });

  factory ReferenceDoctor.fromJson(Map<String, dynamic> json) {
    return ReferenceDoctor(
      refDocCode: json['RefDocCode'],
      refDoctorName: json['Ref_DoctorName'],
      facilityCode: json['FacilityCode'],
      facilityName: json['FacilityName'],
      visitDate: DateTime.parse(json['Visitdate'].replaceAll('/', '-')),
    );
  }
}
