import 'package:intl/intl.dart';

/// Represents a single record returned by `GetPatientDetailsFor_MergingTest`.
/// Used for BOTH the primary barcode lookup and the sugar/glucose barcode
/// lookup — the API shape is identical for both calls.
class MergeTestPatientModel {
  final String fType;
  final int facilityCode;
  final String ward;
  final String facilityName;
  final int visitCode;
  final DateTime? visitDate;
  final String patientName;
  final String orderId;
  final String serviceName;

  MergeTestPatientModel({
    required this.fType,
    required this.facilityCode,
    required this.ward,
    required this.facilityName,
    required this.visitCode,
    required this.visitDate,
    required this.patientName,
    required this.orderId,
    required this.serviceName,
  });

  factory MergeTestPatientModel.fromJson(Map<String, dynamic> json) {
    return MergeTestPatientModel(
      fType: json['FType']?.toString() ?? '',
      facilityCode: int.tryParse(json['FacilityCode']?.toString() ?? '') ?? 0,
      ward: json['Ward']?.toString() ?? '',
      facilityName: json['FacilityName']?.toString() ?? '',
      visitCode: int.tryParse(json['Visitcode']?.toString() ?? '') ?? 0,
      visitDate: _parseDotNetDate(json['Visitdate']?.toString()),
      patientName: (json['PatientName']?.toString() ?? '').trim(),
      orderId: json['OrderID']?.toString() ?? '',
      serviceName: json['ServiceName']?.toString() ?? '',
    );
  }

  /// Parses the ASP.NET `/Date(1766341800000)/` epoch-millis format.
  static DateTime? _parseDotNetDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final match = RegExp(r'/Date\((\d+)\)/').firstMatch(raw);
    if (match == null) return null;
    final millis = int.tryParse(match.group(1) ?? '');
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  /// "Susjjsjdj  oasyahahhs [M/20 YEAR]" -> "Susjjsjdj oasyahahhs"
  String get displayName {
    final idx = patientName.indexOf('[');
    final name = idx == -1 ? patientName : patientName.substring(0, idx);
    return name.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// "Susjjsjdj  oasyahahhs [M/20 YEAR]" -> "M/20 YEAR"
  String get genderAgeInfo {
    final match = RegExp(r'\[(.*?)\]').firstMatch(patientName);
    return match?.group(1) ?? '';
  }

  String get formattedVisitDate {
    if (visitDate == null) return '-';
    return DateFormat('dd MMM yyyy, hh:mm a').format(visitDate!);
  }
}
