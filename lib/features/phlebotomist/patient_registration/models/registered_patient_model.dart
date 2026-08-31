// models/registered_patient_model.dart
class RegisteredPatient {
  final String orderno;
  final String fullname;
  final String age;
  final String serviceName;
  final String patStatus;
  final int importStatus;
  final String adddate;
  final String facilityID;
  final String trfFilePath;
  final int trfStatus;

  // New fields
  final String? opdNumber;
  final String? basicReceipt;
  final String? advanceReceipt;
  final String? patientType;
  final String? mobile;
  final int? billFreezed;

  RegisteredPatient({
    required this.orderno,
    required this.fullname,
    required this.age,
    required this.serviceName,
    required this.patStatus,
    required this.importStatus,
    required this.adddate,
    required this.facilityID,
    this.trfFilePath = '',
    this.trfStatus = 0,
    this.opdNumber,
    this.basicReceipt,
    this.advanceReceipt,
    this.patientType,
    this.mobile,
    this.billFreezed,
  });

  factory RegisteredPatient.fromJson(Map<String, dynamic> json) {
    return RegisteredPatient(
      orderno: json['orderno'] ?? '',
      fullname: json['Fullname'] ?? '',
      age: json['Age'] ?? '',
      serviceName: json['ServiceName'] ?? '',
      patStatus: json['PatStatus'] ?? '',
      importStatus: json['Import_status'] ?? 0,
      adddate: json['Adddate'] ?? '',
      facilityID: json['FacilityID'] ?? '',
      trfFilePath: json['TrfFilePath'] ?? '',
      trfStatus: json['TRFStatus'] ?? 0,
      opdNumber: json['OPDNumber']?.toString(),
      basicReceipt: json['basic_receiptnumber']?.toString(),
      advanceReceipt: json['Advance_receiptnumber']?.toString(),
      patientType: json['patienttype']?.toString(),
      mobile: json['mobile']?.toString(),
      billFreezed: json['Bill_Freezed'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderno': orderno,
      'fullname': fullname,
      'age': age,
      'serviceName': serviceName,
      'patStatus': patStatus,
      'importStatus': importStatus,
      'Adddate': adddate,
      'facilityID': facilityID,
      'trfFilePath': trfFilePath,
      'trfStatus': trfStatus,
      'opdNumber': opdNumber,
      'basicReceipt': basicReceipt,
      'advanceReceipt': advanceReceipt,
      'patientType': patientType,
      'mobile': mobile,
      'billFreezed': billFreezed,
    };
  }

  /*DateTime? get parsedDate {
    try {
      final dateString = adddate.replaceAll(RegExp(r'[^0-9]'), '');
      if (dateString.isNotEmpty) {
        final timestamp = int.parse(dateString);
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    } catch (_) {
      return null;
    }
    return null;
  }*/
  DateTime? get parsedDate {
    return DateTime.tryParse(adddate);
  }

  bool get hasValidTrfLink => trfFilePath.isNotEmpty && trfStatus == 1;
}

class RegisteredPatientResponse {
  final String status;
  final String message;
  final List<RegisteredPatient> output;

  RegisteredPatientResponse({
    required this.status,
    required this.message,
    required this.output,
  });

  factory RegisteredPatientResponse.fromJson(Map<String, dynamic> json) {
    return RegisteredPatientResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      output:
          (json['output'] as List?)
              ?.map((e) => RegisteredPatient.fromJson(e))
              .toList() ??
          [],
    );
  }
}
