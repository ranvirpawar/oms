import 'dart:convert';

import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
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

      if (!isSuccess) {
        final message = (body['message'] as String?)?.trim() ?? '';
        final output = body['output'];


        if (output == null && _isNoDataMessage(message)) {
          return const <AssignedPatient>[];
        }

        throw PatientQueueException(
          message.isEmpty ? 'Unable to load your patient queue.' : message,
        );
      }


      final output = body['output'];

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
      'RescheduleDate': rescheduleDate?.toIso8601String() ?? null,
      'RescheduleStartTime': rescheduleStartTime ?? null,
      'RescheduleEndTime': rescheduleEndTime ?? null,
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

  Future<bool> startRoute(String patientId) async {
    // TODO: wire to the real start-route endpoint once available.
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }
}
// final dummyData = {
//   "status": "Success",
//   "message": "Order details",
//   "output": {
//     "SampleCollectionOrderID": 33,
//     "OMSOrderID": "CL26090100000033",
//     "OrderID": "TEST-ORD-20260901-005",
//     "PatientID": "PAT-1004",
//     "OrderAssignDetailID": 16,
//     "AssignStatusID": 1,
//     "UserID": 17,
//     "UserRosterID": 1,
//     "Status": "Assigned",
//     "Priority": "High",
//     "VisitType": "Clinic",
//     "Title": "Mr",
//     "FirstName": "Rakul",
//     "MiddleName": null,
//     "LastName": "Patil",
//     "PatientName": "Mr Rakul  Patil",
//     "Age": "34 Years",
//     "Gender": "Male",
//     "photoUrl": null,
//     "MobileNumber": "9876501234",
//     "AddressLine": "CIDCO",
//     "City": "Aurangabad",
//     "Pincode": "431001",
//     "Latitude": 19.8762,
//     "Longitude": 75.3433,
//     "Address": "CIDCO, Aurangabad, 431001",
//     "Clinic": "Chhatrapati Sambhajinagar GP 1",
//     "SlotDate": "2026-09-02T10:54:01.74",
//     "SlotStartTime": "09:00:00",
//     "SlotEndTime": "09:30:00",
//     "DistanceInKM": null,
//     "FastingRequired": "Fasting Required",
//     "Tests": [
//       {
//         "OrderID": "TEST-ORD-20260901-005",
//         "TestID": 1,
//         "TestName": "Free T4",
//         "SampleTypeName": "Serum",
//         "TubeId": 3,
//         "TubeContent": "Plain Tube",
//         "FastingRequired": "Fasting Not Required"
//       },
//       {
//         "OrderID": "TEST-ORD-20260901-005",
//         "TestID": 2,
//         "TestName": "T3",
//         "SampleTypeName": "Serum",
//         "TubeId": 3,
//         "TubeContent": "Plain Tube",
//         "FastingRequired": "Fasting Not Required"
//       }
//     ]
//   }
// };
// final output = dummyData['output'];