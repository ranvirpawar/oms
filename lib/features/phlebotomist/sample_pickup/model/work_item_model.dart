// models/work_item.dart

class WorkItem {
  final int workId;
  final int sampleCollectionLotId;
  final int facilityCode;
  final int userId;
  final String facilityName;
  final double latitude;
  final double longitude;
  final String createdDate;
  final String time;
  final String fileName;
  final int sampleCount;
  final int tubeCount;
  final int? isSubmittedAccepted;
  final int? trfP;
  final int? tubeCountP;
  final int? tubeCountL;
  final int? trfCountL;

  // New fields for Runnerboy
  final int? trfR;
  final int? tubeCountR;

  WorkItem({
    required this.workId,
    required this.sampleCollectionLotId,
    required this.facilityCode,
    required this.userId,
    required this.facilityName,
    required this.latitude,
    required this.longitude,
    required this.createdDate,
    required this.time,
    required this.fileName,
    required this.sampleCount,
    required this.tubeCount,
    this.isSubmittedAccepted,
    this.trfP,
    this.tubeCountP,
    this.tubeCountL,
    this.trfCountL,
    this.trfR,
    this.tubeCountR,
  });

  factory WorkItem.fromJson(Map<String, dynamic> json) {
    return WorkItem(
      workId: json['WorkID'],
      sampleCollectionLotId: json['SampleCollectionLotID'],
      facilityCode: json['FacilityCode'],
      userId: json['userid'],
      facilityName: json['Facilityname'],
      latitude: (json['LATITUDE'] as num).toDouble(),
      longitude: (json['LONGITUDE'] as num).toDouble(),
      createdDate: json['CreatedDate'],
      time: json['time'],
      fileName: json['FileName'],
      sampleCount: json['SampleCount'],
      tubeCount: json['TubeCount'],
      isSubmittedAccepted: json['IsSubmittedAccepted'],
      trfP: json['TRF_P'],
      tubeCountP: json['Tubecount_P'],
      tubeCountL: json['Tubecount_L'],
      trfCountL: json['TRFcount_L'],

      // Added Runnerboy values
      trfR: json['TRF_R'],
      tubeCountR: json['Tubecount_R'],
    );
  }
}
