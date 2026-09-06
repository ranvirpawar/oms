import 'dart:convert';

import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/controller/patient_queue_controller.dart';
import 'package:lifenity_connect/network/app_urls.dart';
import 'package:lifenity_connect/utils/helper_functions/helper_methods.dart';

import '../../../../network/api_client.dart';
import '../model/patient_queue_model.dart';

class PatientQueueException implements Exception {
  final String message;
  final bool isNetworkError;

  PatientQueueException(this.message, {this.isNetworkError = false});

  @override
  String toString() => message;
}

/// Status codes for the shared updateOrder "assign status" endpoint.
class AssignStatus {
  static const int accepted = 2;
  static const int rejected = 3;
  static const int rescheduled = 4;
}

class PatientQueueService {
  final APIClient _apiClient = Get.find<APIClient>();

  /// True when the backend's failure message represents "no data" (e.g.
  /// "No record found") rather than a genuine error.
  static bool _isNoDataMessage(String message) {
    final lower = message.toLowerCase();
    return lower.contains('no record') || lower.contains('no data');
  }

  Future<List<AssignedPatient>> fetchAssignedPatients({
    required String userId,
  }) async {
    try {
      final response = await _apiClient.get(
        '${AppUrls.getOrdersList}?userId=$userId',
      );

      final Map<String, dynamic> body = response.data is String
          ? jsonDecode(response.data as String) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;

      final isSuccess =
          (body['status'] as String?)?.toLowerCase() == 'success';

      /*if (!isSuccess) {
        final message = (body['message'] as String?)?.trim() ?? '';
        final output = body['output'];


        if (output == null && _isNoDataMessage(message)) {
          return const <AssignedPatient>[];
        }

        throw PatientQueueException(
          message.isEmpty ? 'Unable to load your patient queue.' : message,
        );
      }*/


      final output = dummyData['output'];
      // final output = body['output'];



      final List<dynamic> list = output is List ? output : [output];

      return list
          .whereType<Map<String, dynamic>>()
          .map(AssignedPatient.fromJson)
          .toList();
    } on PatientQueueException {
      rethrow;
    } catch (e) {
      kPrint(e.toString());
      throw PatientQueueException(
        'Unable to load your patient queue. Please check your connection and try again.',
        isNetworkError: true,
      );
    }
  }

  /// Single call used by accept / reject / reschedule — same endpoint,
  /// same envelope, only AssignStatusID (and the reschedule/reject-only
  /// fields) differ.
  Future<bool> _updateAssignStatus(
    AssignedPatient patient, {
    required int assignStatusId,
    required int updatedBy,
    DateTime? rescheduleDate,
    String? rescheduleStartTime,
    String? rescheduleEndTime,
    int? rejectReasonId,
  }) async {
    final body = {
      'Type_SampleOrderchnags': [
        {
          'OrderAssignDetailID': patient.orderAssignDetailId ?? 0,
          'SampleCollectionOrderID': patient.sampleCollectionOrderId ?? 0,
          'PatientID': patient.patientId ?? '',
          'OMSOrderID': patient.omsOrderId ?? patient.orderId ?? '',
          'UserID': updatedBy,
          'UserRosterID': patient.userRosterId ?? 0,
        },
      ],
      'AssignStatusID': assignStatusId,
      'RescheduleDate': rescheduleDate?.toIso8601String(),
      'RescheduleStartTime': rescheduleStartTime,
      'RescheduleEndTime': rescheduleEndTime,
      'AssignRejectReasonID': rejectReasonId ?? 0,
      'UpdatedBy': updatedBy,
    };

    try {
      final response = await _apiClient.post(AppUrls.updateOrder, data: body);
      final Map<String, dynamic> respBody = response.data is String
          ? jsonDecode(response.data as String) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;
      return (respBody['status'] as String?)?.toLowerCase() == 'success';
    } catch (_) {
      throw PatientQueueException(
        'Unable to update this order. Please check your connection and try again.',
        isNetworkError: true,
      );
    }
  }

  Future<bool> acceptAndStart(
    AssignedPatient patient, {
    required int updatedBy,
  }) {
    return _updateAssignStatus(
      patient,
      assignStatusId: AssignStatus.accepted,
      updatedBy: updatedBy,
    );
  }

  Future<bool> reject(
    AssignedPatient patient, {
    required int updatedBy,
    int? reasonId,
  }) {
    return _updateAssignStatus(
      patient,
      assignStatusId: AssignStatus.rejected,
      updatedBy: updatedBy,
      rejectReasonId: reasonId,
    );
  }

  Future<bool> reschedule(
    AssignedPatient patient, {
    required int updatedBy,
    required DateTime newDate,
    required String startTime,
    required String endTime,
  }) {
    return _updateAssignStatus(
      patient,
      assignStatusId: AssignStatus.rescheduled,
      updatedBy: updatedBy,
      rescheduleDate: newDate,
      rescheduleStartTime: startTime,
      rescheduleEndTime: endTime,
    );
  }
}
final dummyPatientList = {
  'status': 'Success',
  'message': 'Order details',
  'output': [
    {
      'SampleCollectionOrderID': 153,
      'OMSOrderID': 'CL26090600000153',
      'OrderID': 'ORD-TEST-1788676562182',
      'PatientID': 'PAT-CL3-20260907-01',
      'OrderAssignDetailID': 141,
      'AssignStatusID': 2,
      'UserID': 17,
      'UserRosterID': 7,
      'Status': 'Accepted',
      'Priority': null,
      'VisitType': 'Clinic',
      'Title': null,
      'FirstName': 'Aarav',
      'MiddleName': null,
      'LastName': 'Sharma',
      'PatientName': 'Aarav Sharma',
      'Age': '',
      'Gender': 'Male',
      'photoUrl': null,
      'MobileNumber': '7036925814',
      'AddressLine': '1 MG Road',
      'City': 'Chhatrapati Sambhajinagar',
      'Pincode': '431001',
      'Latitude': null,
      'Longitude': null,
      'Address': '1 MG Road, Chhatrapati Sambhajinagar, 431001',
      'Clinic': 'Chhatrapati Sambhajinagar GP 1',
      'SlotDate': '2026-09-06T16:56:33.947',
      'SlotStartTime': '08:00:00',
      'SlotEndTime': '08:30:00',
      'DistanceInKM': null,
      'FastingRequired': 'Fasting Not Required',
      'IsRoute': 'No',
      'Tests': [
        {
          'OrderID': 'ORD-TEST-1788676562182',
          'TestID': 10,
          'TestName': 'Albumin',
          'SampleTypeName': 'Serum',
          'TubeId': 3,
          'TubeContent': 'Plain Tube',
          'FastingRequired': 'Fasting Not Required',
        },
        {
          'OrderID': 'ORD-TEST-1788676562182',
          'TestID': 23,
          'TestName': 'Alkaline Phosphatase',
          'SampleTypeName': 'Serum',
          'TubeId': 3,
          'TubeContent': 'Plain Tube',
          'FastingRequired': 'Fasting Not Required',
        },
      ],
    },
    {
      'SampleCollectionOrderID': 154,
      'OMSOrderID': 'CL26090600000154',
      'OrderID': 'ORD-CL3-20260907-02',
      'PatientID': 'PAT-CL3-20260907-02',
      'OrderAssignDetailID': 142,
      'AssignStatusID': 1,
      'UserID': 17,
      'UserRosterID': 7,
      'Status': 'Assigned',
      'Priority': null,
      'VisitType': 'Clinic',
      'Title': null,
      'FirstName': 'Diya',
      'MiddleName': null,
      'LastName': 'Deshmukh',
      'PatientName': 'Diya Deshmukh',
      'Age': '',
      'Gender': 'Female',
      'photoUrl': null,
      'MobileNumber': '8703692581',
      'AddressLine': '2 MG Road',
      'City': 'Chhatrapati Sambhajinagar',
      'Pincode': '431001',
      'Latitude': null,
      'Longitude': null,
      'Address': '2 MG Road, Chhatrapati Sambhajinagar, 431001',
      'Clinic': 'Chhatrapati Sambhajinagar GP 1',
      'SlotDate': '2026-09-06T16:57:06.047',
      'SlotStartTime': '08:30:00',
      'SlotEndTime': '09:00:00',
      'DistanceInKM': null,
      'FastingRequired': 'Fasting Not Required',
      'IsRoute': 'No',
      'Tests': [
        {
          'OrderID': 'ORD-CL3-20260907-02',
          'TestID': 3,
          'TestName': 'Amylase',
          'SampleTypeName': 'Serum',
          'TubeId': 3,
          'TubeContent': 'Plain Tube',
          'FastingRequired': 'Fasting Not Required',
        },
        {
          'OrderID': 'ORD-CL3-20260907-02',
          'TestID': 55,
          'TestName': 'Bilirubin - Direct',
          'SampleTypeName': 'Serum',
          'TubeId': 3,
          'TubeContent': 'Plain Tube',
          'FastingRequired': 'Fasting Not Required',
        },
      ],
    },
    {
      'SampleCollectionOrderID': 155,
      'OMSOrderID': 'CL26090600000155',
      'OrderID': 'ORD-CL3-20260907-03',
      'PatientID': 'PAT-CL3-20260907-03',
      'OrderAssignDetailID': 143,
      'AssignStatusID': 2,
      'UserID': 17,
      'UserRosterID': 7,
      'Status': 'Accepted',
      'Priority': null,
      'VisitType': 'Clinic',
      'Title': null,
      'FirstName': 'Aditya',
      'MiddleName': null,
      'LastName': 'Reddy',
      'PatientName': 'Aditya Reddy',
      'Age': '',
      'Gender': 'Male',
      'photoUrl': null,
      'MobileNumber': '9470369258',
      'AddressLine': '3 MG Road',
      'City': 'Chhatrapati Sambhajinagar',
      'Pincode': '431001',
      'Latitude': null,
      'Longitude': null,
      'Address': '3 MG Road, Chhatrapati Sambhajinagar, 431001',
      'Clinic': 'Chhatrapati Sambhajinagar GP 1',
      'SlotDate': '2026-09-06T16:57:28.557',
      'SlotStartTime': '09:00:00',
      'SlotEndTime': '09:30:00',
      'DistanceInKM': null,
      'FastingRequired': 'Fasting Not Required',
      'IsRoute': 'End',
      'Tests': [
        {
          'OrderID': 'ORD-CL3-20260907-03',
          'TestID': 62,
          'TestName': 'Bilirubin - Total',
          'SampleTypeName': 'Serum',
          'TubeId': 3,
          'TubeContent': 'Plain Tube',
          'FastingRequired': 'Fasting Not Required',
        },
        {
          'OrderID': 'ORD-CL3-20260907-03',
          'TestID': 67,
          'TestName': 'Bilirubin - Indirect',
          'SampleTypeName': 'Serum',
          'TubeId': 3,
          'TubeContent': 'Plain Tube',
          'FastingRequired': 'Fasting Not Required',
        },
      ],
    },
    {
      'SampleCollectionOrderID': 156,
      'OMSOrderID': 'CL26090600000156',
      'OrderID': 'ORD-CL3-20260907-04',
      'PatientID': 'PAT-CL3-20260907-04',
      'OrderAssignDetailID': 144,
      'AssignStatusID': 1,
      'UserID': 17,
      'UserRosterID': 7,
      'Status': 'Assigned',
      'Priority': null,
      'VisitType': 'Clinic',
      'Title': null,
      'FirstName': 'Kavya',
      'MiddleName': null,
      'LastName': 'Iyer',
      'PatientName': 'Kavya Iyer',
      'Age': '',
      'Gender': 'Female',
      'photoUrl': null,
      'MobileNumber': '6147036925',
      'AddressLine': '4 MG Road',
      'City': 'Chhatrapati Sambhajinagar',
      'Pincode': '431001',
      'Latitude': null,
      'Longitude': null,
      'Address': '4 MG Road, Chhatrapati Sambhajinagar, 431001',
      'Clinic': 'Chhatrapati Sambhajinagar GP 1',
      'SlotDate': '2026-09-06T16:57:38.073',
      'SlotStartTime': '09:30:00',
      'SlotEndTime': '10:00:00',
      'DistanceInKM': null,
      'FastingRequired': 'Fasting Not Required',
      'IsRoute': 'No',
      'Tests': [
        {
          'OrderID': 'ORD-CL3-20260907-04',
          'TestID': 28,
          'TestName': 'BUN (Blood Urea Nitrogen)',
          'SampleTypeName': 'Serum',
          'TubeId': 3,
          'TubeContent': 'Plain Tube',
          'FastingRequired': 'Fasting Not Required',
        },
        {
          'OrderID': 'ORD-CL3-20260907-04',
          'TestID': 61,
          'TestName': 'Calcium Total',
          'SampleTypeName': 'Serum',
          'TubeId': 3,
          'TubeContent': 'Plain Tube',
          'FastingRequired': 'Fasting Not Required',
        },
      ],
    },
    {
      'SampleCollectionOrderID': 157,
      'OMSOrderID': 'CL26090600000157',
      'OrderID': 'ORD-CL3-20260907-05',
      'PatientID': 'PAT-CL3-20260907-05',
      'OrderAssignDetailID': 145,
      'AssignStatusID': 1,
      'UserID': 17,
      'UserRosterID': 7,
      'Status': 'Assigned',
      'Priority': null,
      'VisitType': 'Clinic',
      'Title': null,
      'FirstName': 'Kabir',
      'MiddleName': null,
      'LastName': 'Patil',
      'PatientName': 'Kabir Patil',
      'Age': '',
      'Gender': 'Male',
      'photoUrl': null,
      'MobileNumber': '7814703692',
      'AddressLine': '5 MG Road',
      'City': 'Chhatrapati Sambhajinagar',
      'Pincode': '431001',
      'Latitude': null,
      'Longitude': null,
      'Address': '5 MG Road, Chhatrapati Sambhajinagar, 431001',
      'Clinic': 'Chhatrapati Sambhajinagar GP 1',
      'SlotDate': '2026-09-06T16:57:47.2',
      'SlotStartTime': '10:00:00',
      'SlotEndTime': '10:30:00',
      'DistanceInKM': null,
      'FastingRequired': 'Fasting Not Required',
      'IsRoute': 'No',
      'Tests': [
        {
          'OrderID': 'ORD-CL3-20260907-05',
          'TestID': 63,
          'TestName': 'Chlorides',
          'SampleTypeName': 'Serum',
          'TubeId': 3,
          'TubeContent': 'Plain Tube',
          'FastingRequired': 'Fasting Not Required',
        },
        {
          'OrderID': 'ORD-CL3-20260907-05',
          'TestID': 94,
          'TestName': 'Cholesterol - Total',
          'SampleTypeName': 'Serum',
          'TubeId': 3,
          'TubeContent': 'Plain Tube',
          'FastingRequired': 'Fasting Required',
        },
      ],
    },
    {
      'SampleCollectionOrderID': 158,
      'OMSOrderID': 'CL26090600000158',
      'OrderID': 'ORD-CL3-20260907-06',
      'PatientID': 'PAT-CL3-20260907-06',
      'OrderAssignDetailID': 146,
      'AssignStatusID': 1,
      'UserID': 17,
      'UserRosterID': 7,
      'Status': 'Assigned',
      'Priority': null,
      'VisitType': 'Clinic',
      'Title': null,
      'FirstName': 'Priya',
      'MiddleName': null,
      'LastName': 'Joshi',
      'PatientName': 'Priya Joshi',
      'Age': '',
      'Gender': 'Female',
      'photoUrl': null,
      'MobileNumber': '8581470369',
      'AddressLine': '6 MG Road',
      'City': 'Chhatrapati Sambhajinagar',
      'Pincode': '431001',
      'Latitude': null,
      'Longitude': null,
      'Address': '6 MG Road, Chhatrapati Sambhajinagar, 431001',
      'Clinic': 'Chhatrapati Sambhajinagar GP 1',
      'SlotDate': '2026-09-06T16:57:55.943',
      'SlotStartTime': '10:30:00',
      'SlotEndTime': '11:00:00',
      'DistanceInKM': null,
      'FastingRequired': 'Fasting Not Required',
      'IsRoute': 'No',
      'Tests': [
        {
          'OrderID': 'ORD-CL3-20260907-06',
          'TestID': 17,
          'TestName': 'Cholesterol LDL Direct',
          'SampleTypeName': 'Serum',
          'TubeId': 3,
          'TubeContent': 'Plain Tube',
          'FastingRequired': 'Fasting Required',
        },
        {
          'OrderID': 'ORD-CL3-20260907-06',
          'TestID': 44,
          'TestName': 'Cholesterol HDL Direct',
          'SampleTypeName': 'Serum',
          'TubeId': 3,
          'TubeContent': 'Plain Tube',
          'FastingRequired': 'Fasting Required',
        },
      ],
    },
    {
      'SampleCollectionOrderID': 159,
      'OMSOrderID': 'CL26090600000159',
      'OrderID': 'ORD-CL3-20260907-07',
      'PatientID': 'PAT-CL3-20260907-07',
      'OrderAssignDetailID': 147,
      'AssignStatusID': 1,
      'UserID': 17,
      'UserRosterID': 7,
      'Status': 'Assigned',
      'Priority': null,
      'VisitType': 'Clinic',
      'Title': null,
      'FirstName': 'Aryan',
      'MiddleName': null,
      'LastName': 'Gupta',
      'PatientName': 'Aryan Gupta',
      'Age': '',
      'Gender': 'Male',
      'photoUrl': null,
      'MobileNumber': '9258147036',
      'AddressLine': '7 MG Road',
      'City': 'Chhatrapati Sambhajinagar',
      'Pincode': '431001',
      'Latitude': null,
      'Longitude': null,
      'Address': '7 MG Road, Chhatrapati Sambhajinagar, 431001',
      'Clinic': 'Chhatrapati Sambhajinagar GP 1',
      'SlotDate': '2026-09-06T16:58:08.003',
      'SlotStartTime': '11:00:00',
      'SlotEndTime': '11:30:00',
      'DistanceInKM': null,
      'FastingRequired': 'Fasting Not Required',
      'IsRoute': 'No',
      'Tests': [
        {
          'OrderID': 'ORD-CL3-20260907-07',
          'TestID': 45,
          'TestName': 'Gamma Glutamyl Transferase Test (GGT)',
          'SampleTypeName': 'Serum',
          'TubeId': 3,
          'TubeContent': 'Plain Tube',
          'FastingRequired': 'Fasting Not Required',
        },
        {
          'OrderID': 'ORD-CL3-20260907-07',
          'TestID': 46,
          'TestName': 'Glucose (Blood Sugar), Fasting',
          'SampleTypeName': 'Plasma F',
          'TubeId': 6,
          'TubeContent': 'Sodium fluoride vial',
          'FastingRequired': 'Fasting Required',
        },
      ],
    },
    {
      'SampleCollectionOrderID': 160,
      'OMSOrderID': 'CL26090600000160',
      'OrderID': 'ORD-CL3-20260907-08',
      'PatientID': 'PAT-CL3-20260907-08',
      'OrderAssignDetailID': 148,
      'AssignStatusID': 1,
      'UserID': 17,
      'UserRosterID': 7,
      'Status': 'Assigned',
      'Priority': null,
      'VisitType': 'Clinic',
      'Title': null,
      'FirstName': 'Saanvi',
      'MiddleName': null,
      'LastName': 'Verma',
      'PatientName': 'Saanvi Verma',
      'Age': '',
      'Gender': 'Female',
      'photoUrl': null,
      'MobileNumber': '6925814703',
      'AddressLine': '8 MG Road',
      'City': 'Chhatrapati Sambhajinagar',
      'Pincode': '431001',
      'Latitude': null,
      'Longitude': null,
      'Address': '8 MG Road, Chhatrapati Sambhajinagar, 431001',
      'Clinic': 'Chhatrapati Sambhajinagar GP 1',
      'SlotDate': '2026-09-06T16:58:14.567',
      'SlotStartTime': '11:30:00',
      'SlotEndTime': '12:00:00',
      'DistanceInKM': null,
      'FastingRequired': 'Fasting Not Required',
      'IsRoute': 'No',
      'Tests': [
        {
          'OrderID': 'ORD-CL3-20260907-08',
          'TestID': 53,
          'TestName': 'Glucose (Blood Sugar), PP (Post Prandial)',
          'SampleTypeName': 'Plasma',
          'TubeId': 6,
          'TubeContent': 'Sodium fluoride vial',
          'FastingRequired': 'Fasting Required',
        },
        {
          'OrderID': 'ORD-CL3-20260907-08',
          'TestID': 57,
          'TestName': 'Glucose (Blood Sugar), Random',
          'SampleTypeName': 'Plasma R',
          'TubeId': 6,
          'TubeContent': 'Sodium fluoride vial',
          'FastingRequired': 'Fasting Not Required',
        },
      ],
    },
  ],
};
final dummyData = {
  "status": "Success",
  "message": "Order details",
  "output": dummyPatientList
};

