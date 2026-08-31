class SummaryModel {
  final int srno;
  final String countDate;
  final String countTime;
  final int districtCount;
  final int facilityCount;
  final int patientCount;
  final int testTotal;
  final int reportedCount;
  final int reportedPendingCount;
  final String patientCountToday;
  final String testTotalToday;
  final String reportedCountToday;
  final String reportedPendingCountToday;
  final String facilityCountToday;
  final String patientCountYesterday;
  final String testTotalYesterday;
  final String reportedCountYesterday;
  final String reportedPendingCountYesterday;
  final String facilityCountYesterday;
  final String onboarded;
  final String present;
  final String absent;
  final String presentPerc;
  final String absentPerc;
  final String currentMonthSamp;
  final String pre1stMonthSamp;
  final String pre2ndMonthSamp;
  final String holiday;
  final String holidayPercentage;
  final String isWeekOff;
  final String isWeekOffPercentage;

  SummaryModel({
    required this.srno,
    required this.countDate,
    required this.countTime,
    required this.districtCount,
    required this.facilityCount,
    required this.patientCount,
    required this.testTotal,
    required this.reportedCount,
    required this.reportedPendingCount,
    required this.patientCountToday,
    required this.testTotalToday,
    required this.reportedCountToday,
    required this.reportedPendingCountToday,
    required this.facilityCountToday,
    required this.patientCountYesterday,
    required this.testTotalYesterday,
    required this.reportedCountYesterday,
    required this.reportedPendingCountYesterday,
    required this.facilityCountYesterday,
    required this.onboarded,
    required this.present,
    required this.absent,
    required this.presentPerc,
    required this.absentPerc,
    required this.currentMonthSamp,
    required this.pre1stMonthSamp,
    required this.pre2ndMonthSamp,
    required this.holiday,
    required this.holidayPercentage,
    required this.isWeekOff,
    required this.isWeekOffPercentage,
  });

  factory SummaryModel.fromJson(Map<String, dynamic> json) {
    return SummaryModel(
      srno: json['srno'] ?? 0,
      countDate: json['COUNTDATE'] ?? '',
      countTime: json['COUNTTIME'] ?? '',
      districtCount: json['DistrictCount'] ?? 0,
      facilityCount: json['FacilityCount'] ?? 0,
      patientCount: json['PatientCount'] ?? 0,
      testTotal: json['TEST_TOTAL'] ?? 0,
      reportedCount: json['REPORTED_COUNT'] ?? 0,
      reportedPendingCount: json['REPORTED_PENDING_COUNT'] ?? 0,
      patientCountToday: json['PatientCount_TODAY'] ?? '0',
      testTotalToday: json['TEST_TOTAL_TODAY'] ?? '0',
      reportedCountToday: json['REPORTED_COUNT_TODAY'] ?? '0',
      reportedPendingCountToday: json['REPORTED_PENDING_COUNT_TODAY'] ?? '0',
      facilityCountToday: json['FacilityCount_Today'] ?? '0',
      patientCountYesterday: json['PatientCount_YESTERDAY'] ?? '0',
      testTotalYesterday: json['TEST_TOTAL_YESTERDAY'] ?? '0',
      reportedCountYesterday: json['REPORTED_COUNT_YESTERDAY'] ?? '0',
      reportedPendingCountYesterday: json['REPORTED_PENDING_COUNT_YESTERDAY'] ?? '0',
      facilityCountYesterday: json['FacilityCount_YESTERDAY'] ?? '0',
      onboarded: json['ONBOARDED'] ?? '0',
      present: json['present'] ?? '0',
      absent: json['ABSEND'] ?? '0',
      presentPerc: json['Presentperc'] ?? '0',
      absentPerc: json['AbsentPerc'] ?? '0',
      currentMonthSamp: json['CURRENT_MONTH_SAMP'] ?? '0',
      pre1stMonthSamp: json['PRE_1ST_MONTH_SAMP'] ?? '0',
      pre2ndMonthSamp: json['PRE_2ND_MONTH_SAMP'] ?? '0',
      holiday: json['Holiday'] ?? '0',
      holidayPercentage: json['HolidayPercentage'] ?? '0',
      isWeekOff: json['IsWeekOff'] ?? '0',
      isWeekOffPercentage: json['IsWeekOffPercentage'] ?? '0',
    );
  }
}