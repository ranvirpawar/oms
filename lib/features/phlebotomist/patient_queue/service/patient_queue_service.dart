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

  /// Formats a [DateTime] the way the available-slots API expects its
  /// `appointmentDate` query param (`yyyy-MM-ddTHH:mm:ss`).
  static String _toApiDate(DateTime date) {
    String pad(int v) => v.toString().padLeft(2, '0');
    return '${date.year.toString().padLeft(4, '0')}-'
        '${pad(date.month)}-${pad(date.day)}T'
        '${pad(date.hour)}:${pad(date.minute)}:${pad(date.second)}';
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
/*
      if (!isSuccess) {
        final message = (body['message'] as String?)?.trim() ?? '';
        final output = body['output'];


        if (output == null && _isNoDataMessage(message)) {
          return const <AssignedPatient>[];
        }

        throw PatientQueueException(
          message.isEmpty ? 'Unable to load your patient queue.' : message,
        );
      }*/


      // final output = body['output'];
      final output = dummyPatientList['output'];



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

  /// Single call used by accept / reject — same endpoint, same envelope,
  /// only AssignStatusID (and the reject-only reason id) differ.
  /// Single call used by accept / reject / reschedule — same endpoint, same
  /// envelope, only AssignStatusID (and the reject/reschedule-only fields)
  /// differ.
  Future<bool> _updateAssignStatus(
      AssignedPatient patient, {
        required int assignStatusId,
        required int updatedBy,
        int? rejectReasonId,
        int? slotId,
        int? rescheduleReasonId,
        DateTime? rescheduleDate,
        String? rescheduleStartTime,
        String? rescheduleEndTime,
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
      'SlotID': slotId ?? 0,
      'RescheduleReasoneID': rescheduleReasonId ?? 0,
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
  /// Reschedules via the shared `updateOrder` endpoint (AssignStatusID = 4)
  /// instead of the dedicated appointment-reschedule API. Takes the picked
  /// slot's id/time window and the mandatory reason id straight from the sheet.
  Future<bool> rescheduleAssignment(
      AssignedPatient patient, {
        required int updatedBy,
        required DateTime rescheduleDate,
        required AvailableSlot slot,
        required int rescheduleReasonId,
      }) {
    return _updateAssignStatus(
      patient,
      assignStatusId: AssignStatus.rescheduled,
      updatedBy: updatedBy,
      slotId: slot.slotId,
      rescheduleReasonId: rescheduleReasonId,
      rescheduleDate: rescheduleDate,
      rescheduleStartTime: null,
      rescheduleEndTime: null,
    );
  }

  /// Fetches the team's available time slots for an appointment date
  /// (`GET user/available-slots`).
  ///
  /// The backend keys slots by [AvailableSlot.slotId]; that id is what the
  /// reschedule insert API expects, so the UI must always pick from this list
  /// rather than inventing free-form start/end times.
  Future<List<AvailableSlot>> fetchAvailableSlots({
    required String userId,
    required DateTime appointmentDate,
  }) async {
    try {
      final response = await _apiClient.get(
        AppUrls.rescheduledSlots,
        queryParameters: {
          'userId': userId,
          'appointmentDate': _toApiDate(appointmentDate),
        },
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
          return const <AvailableSlot>[];
        }

        throw PatientQueueException(
          message.isEmpty ? 'Unable to load available slots.' : message,
        );
      }

      final output = body['output'];
      final List<dynamic> list = output is List ? output : const [];

      return list
          .whereType<Map<String, dynamic>>()
          .map(AvailableSlot.fromJson)
          .toList();
    } on PatientQueueException {
      rethrow;
    } catch (e) {
      kPrint(e.toString());
      throw PatientQueueException(
        'Unable to load available slots. Please check your connection and try again.',
        isNetworkError: true,
      );
    }
  }

  /// Fetches the selectable reschedule reasons (`GetRescheduleReasone`).
  /// Returns an empty list (never throws) so the sheet's mandatory-reason
  /// gate simply stays locked if the backend is unreachable.
  Future<List<RescheduleReason>> fetchRescheduleReasons() async {
    try {
      final response = await _apiClient.get(
        AppUrls.appointmentRescheduledReason,
      );

      final Map<String, dynamic> body = response.data is String
          ? jsonDecode(response.data as String) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;

      final output = body['output'];
      if (output is! List) return const <RescheduleReason>[];

      return output
          .whereType<Map<String, dynamic>>()
          .map(RescheduleReason.fromJson)
          .where((r) => r.id > 0)
          .toList();
    } catch (e) {
      kPrint(e.toString());
      return const <RescheduleReason>[];
    }
  }



}

final dummyPatientList = {
  'status': 'Success',
  'message': 'Order details',
  'output':[
    {
      "SampleCollectionOrderID": 162,
      "OMSOrderID": "CL26090600000162",
      "OrderID": "ORD-CL3-20260907-10",
      "PatientID": "PAT-CL3-20260907-10",
      "OrderAssignDetailID": 150,
      "AssignStatusID": 2,
      "UserID": 17,
      "UserRosterID": 8,
      "Status": "Accepted",
      "Priority": null,
      "VisitType": "Clinic",
      "Title": null,
      "FirstName": "Zoya",
      "MiddleName": null,
      "LastName": "Nair",
      "PatientName": " Zoya  Nair",
      "Age": "",
      "Gender": "Female",
      "photoUrl": null,
      "MobileNumber": "8369258147",
      "AddressLine": "10 MG Road",
      "City": "Chhatrapati Sambhajinagar",
      "Pincode": "431001",
      "Latitude": null,
      "Longitude": null,
      "Address": "10 MG Road, Chhatrapati Sambhajinagar, 431001",
      "Clinic": "Chhatrapati Sambhajinagar GP 1",
      "SlotDate": "2026-09-07T11:52:42.19",
      "SlotStartTime": "12:30:00",
      "SlotEndTime": "13:00:00",
      "DistanceInKM": null,
      "FastingRequired": "Fasting Not Required",
      "IsRoute": "Start",
      "OrderStatusID": 4,
      "OrderStatus": "On The Way",
      "Tests": [
        {
          "OrderID": "ORD-CL3-20260907-10",
          "TestID": 4,
          "TestName": "Magnesium",
          "SampleTypeName": "Serum",
          "TubeId": 3,
          "TubeContent": "Plain Tube",
          "FastingRequired": "Fasting Not Required"
        },
        {
          "OrderID": "ORD-CL3-20260907-10",
          "TestID": 58,
          "TestName": "Phosphorus",
          "SampleTypeName": "Serum",
          "TubeId": 3,
          "TubeContent": "Plain Tube",
          "FastingRequired": "Fasting Not Required"
        }
      ]
    },
    {
      "SampleCollectionOrderID": 163,
      "OMSOrderID": "CL26090600000163",
      "OrderID": "ORD-CL3-20260908-01",
      "PatientID": "PAT-CL3-20260908-01",
      "OrderAssignDetailID": 151,
      "AssignStatusID": 3,
      "UserID": 17,
      "UserRosterID": 8,
      "Status": "Rejected",
      "Priority": null,
      "VisitType": "Clinic",
      "Title": null,
      "FirstName": "Aarav",
      "MiddleName": null,
      "LastName": "Sharma",
      "PatientName": " Aarav  Sharma",
      "Age": "",
      "Gender": "Male",
      "photoUrl": null,
      "MobileNumber": "8581470369",
      "AddressLine": "1 MG Road",
      "City": "Chhatrapati Sambhajinagar",
      "Pincode": "431001",
      "Latitude": null,
      "Longitude": null,
      "Address": "1 MG Road, Chhatrapati Sambhajinagar, 431001",
      "Clinic": "Chhatrapati Sambhajinagar GP 1",
      "SlotDate": "2026-09-07T11:53:10.48",
      "SlotStartTime": "08:00:00",
      "SlotEndTime": "08:30:00",
      "DistanceInKM": null,
      "FastingRequired": "Fasting Not Required",
      "IsRoute": "No",
      "OrderStatusID": 2,
      "OrderStatus": "Assigned",
      "Tests": [
        {
          "OrderID": "ORD-CL3-20260908-01",
          "TestID": 28,
          "TestName": "BUN (Blood Urea Nitrogen)",
          "SampleTypeName": "Serum",
          "TubeId": 3,
          "TubeContent": "Plain Tube",
          "FastingRequired": "Fasting Not Required"
        },
        {
          "OrderID": "ORD-CL3-20260908-01",
          "TestID": 62,
          "TestName": "Bilirubin - Total",
          "SampleTypeName": "Serum",
          "TubeId": 3,
          "TubeContent": "Plain Tube",
          "FastingRequired": "Fasting Not Required"
        }
      ]
    },
    {
      "SampleCollectionOrderID": 164,
      "OMSOrderID": "CL26090600000164",
      "OrderID": "ORD-CL3-20260908-02",
      "PatientID": "PAT-CL3-20260908-02",
      "OrderAssignDetailID": 152,
      "AssignStatusID": 2,
      "UserID": 17,
      "UserRosterID": 8,
      "Status": "Accepted",
      "Priority": null,
      "VisitType": "Clinic",
      "Title": null,
      "FirstName": "Diya",
      "MiddleName": null,
      "LastName": "Deshmukh",
      "PatientName": " Diya  Deshmukh",
      "Age": "",
      "Gender": "Female",
      "photoUrl": null,
      "MobileNumber": "9258147036",
      "AddressLine": "2 MG Road",
      "City": "Chhatrapati Sambhajinagar",
      "Pincode": "431001",
      "Latitude": null,
      "Longitude": null,
      "Address": "2 MG Road, Chhatrapati Sambhajinagar, 431001",
      "Clinic": "Chhatrapati Sambhajinagar GP 1",
      "SlotDate": "2026-09-07T11:54:47.227",
      "SlotStartTime": "08:30:00",
      "SlotEndTime": "09:00:00",
      "DistanceInKM": null,
      "FastingRequired": "Fasting Not Required",
      "IsRoute": "No",
      "OrderStatusID": 3,
      "OrderStatus": "Order Accepted",
      "Tests": [
        {
          "OrderID": "ORD-CL3-20260908-02",
          "TestID": 61,
          "TestName": "Calcium Total",
          "SampleTypeName": "Serum",
          "TubeId": 3,
          "TubeContent": "Plain Tube",
          "FastingRequired": "Fasting Not Required"
        },
        {
          "OrderID": "ORD-CL3-20260908-02",
          "TestID": 63,
          "TestName": "Chlorides",
          "SampleTypeName": "Serum",
          "TubeId": 3,
          "TubeContent": "Plain Tube",
          "FastingRequired": "Fasting Not Required"
        }
      ]
    },
    {
      "SampleCollectionOrderID": 165,
      "OMSOrderID": "CL26090600000165",
      "OrderID": "ORD-CL3-20260908-03",
      "PatientID": "PAT-CL3-20260908-03",
      "OrderAssignDetailID": 153,
      "AssignStatusID": 2,
      "UserID": 17,
      "UserRosterID": 8,
      "Status": "Accepted",
      "Priority": null,
      "VisitType": "Clinic",
      "Title": null,
      "FirstName": "Aditya",
      "MiddleName": null,
      "LastName": "Reddy",
      "PatientName": " Aditya  Reddy",
      "Age": "",
      "Gender": "Male",
      "photoUrl": null,
      "MobileNumber": "6925814703",
      "AddressLine": "3 MG Road",
      "City": "Chhatrapati Sambhajinagar",
      "Pincode": "431001",
      "Latitude": null,
      "Longitude": null,
      "Address": "3 MG Road, Chhatrapati Sambhajinagar, 431001",
      "Clinic": "Chhatrapati Sambhajinagar GP 1",
      "SlotDate": "2026-09-07T11:55:03.56",
      "SlotStartTime": "09:00:00",
      "SlotEndTime": "09:30:00",
      "DistanceInKM": null,
      "FastingRequired": "Fasting Not Required",
      "IsRoute": "No",
      "OrderStatusID": 3,
      "OrderStatus": "Order Accepted",
      "Tests": [
        {
          "OrderID": "ORD-CL3-20260908-03",
          "TestID": 44,
          "TestName": "Cholesterol HDL Direct",
          "SampleTypeName": "Serum",
          "TubeId": 3,
          "TubeContent": "Plain Tube",
          "FastingRequired": "Fasting Required"
        },
        {
          "OrderID": "ORD-CL3-20260908-03",
          "TestID": 94,
          "TestName": "Cholesterol - Total",
          "SampleTypeName": "Serum",
          "TubeId": 3,
          "TubeContent": "Plain Tube",
          "FastingRequired": "Fasting Required"
        }
      ]
    },
    {
      "SampleCollectionOrderID": 166,
      "OMSOrderID": "CL26090600000166",
      "OrderID": "ORD-CL3-20260908-04",
      "PatientID": "PAT-CL3-20260908-04",
      "OrderAssignDetailID": 154,
      "AssignStatusID": 1,
      "UserID": 17,
      "UserRosterID": 8,
      "Status": "Assigned",
      "Priority": null,
      "VisitType": "Clinic",
      "Title": null,
      "FirstName": "Kavya",
      "MiddleName": null,
      "LastName": "Iyer",
      "PatientName": " Kavya  Iyer",
      "Age": "",
      "Gender": "Female",
      "photoUrl": null,
      "MobileNumber": "7692581470",
      "AddressLine": "4 MG Road",
      "City": "Chhatrapati Sambhajinagar",
      "Pincode": "431001",
      "Latitude": null,
      "Longitude": null,
      "Address": "4 MG Road, Chhatrapati Sambhajinagar, 431001",
      "Clinic": "Chhatrapati Sambhajinagar GP 1",
      "SlotDate": "2026-09-07T11:55:19.617",
      "SlotStartTime": "09:30:00",
      "SlotEndTime": "10:00:00",
      "DistanceInKM": null,
      "FastingRequired": "Fasting Not Required",
      "IsRoute": "No",
      "OrderStatusID": 2,
      "OrderStatus": "Assigned",
      "Tests": [
        {
          "OrderID": "ORD-CL3-20260908-04",
          "TestID": 17,
          "TestName": "Cholesterol LDL Direct",
          "SampleTypeName": "Serum",
          "TubeId": 3,
          "TubeContent": "Plain Tube",
          "FastingRequired": "Fasting Required"
        },
        {
          "OrderID": "ORD-CL3-20260908-04",
          "TestID": 45,
          "TestName": "Gamma Glutamyl Transferase Test (GGT)",
          "SampleTypeName": "Serum",
          "TubeId": 3,
          "TubeContent": "Plain Tube",
          "FastingRequired": "Fasting Not Required"
        }
      ]
    },
    {
      "SampleCollectionOrderID": 168,
      "OMSOrderID": "CL26090600000168",
      "OrderID": "ORD-CL3-20260908-06",
      "PatientID": "PAT-CL3-20260908-06",
      "OrderAssignDetailID": 156,
      "AssignStatusID": 2,
      "UserID": 17,
      "UserRosterID": 8,
      "Status": "Accepted",
      "Priority": null,
      "VisitType": "Clinic",
      "Title": null,
      "FirstName": "Priya",
      "MiddleName": null,
      "LastName": "Joshi",
      "PatientName": " Priya  Joshi",
      "Age": "",
      "Gender": "Female",
      "photoUrl": null,
      "MobileNumber": "9036925814",
      "AddressLine": "6 MG Road",
      "City": "Chhatrapati Sambhajinagar",
      "Pincode": "431001",
      "Latitude": null,
      "Longitude": null,
      "Address": "6 MG Road, Chhatrapati Sambhajinagar, 431001",
      "Clinic": "Chhatrapati Sambhajinagar GP 1",
      "SlotDate": "2026-09-07T12:04:20.513",
      "SlotStartTime": "10:30:00",
      "SlotEndTime": "11:00:00",
      "DistanceInKM": null,
      "FastingRequired": "Fasting Not Required",
      "IsRoute": "Start",
      "OrderStatusID": 4,
      "OrderStatus": "On The Way",
      "Tests": [
        {
          "OrderID": "ORD-CL3-20260908-06",
          "TestID": 57,
          "TestName": "Glucose (Blood Sugar), Random",
          "SampleTypeName": "Plasma R",
          "TubeId": 6,
          "TubeContent": "Sodium fluoride vial",
          "FastingRequired": "Fasting Not Required"
        },
        {
          "OrderID": "ORD-CL3-20260908-06",
          "TestID": 83,
          "TestName": "Iron",
          "SampleTypeName": "Serum",
          "TubeId": 3,
          "TubeContent": "Plain Tube",
          "FastingRequired": "Fasting Not Required"
        }
      ]
    },
    {
      "SampleCollectionOrderID": 185,
      "OMSOrderID": "CL26090700000185",
      "OrderID": "ORD-102222052",
      "PatientID": "PAT-10002",
      "OrderAssignDetailID": 168,
      "AssignStatusID": 1,
      "UserID": 17,
      "UserRosterID": 2,
      "Status": "Assigned",
      "Priority": null,
      "VisitType": "Clinic",
      "Title": "Mr.",
      "FirstName": "Rahul",
      "MiddleName": "S.",
      "LastName": "Sharma",
      "PatientName": "Mr. Rahul S. Sharma",
      "Age": "36 Years",
      "Gender": "Male",
      "photoUrl": null,
      "MobileNumber": "9999999999",
      "AddressLine": "45 Park Street",
      "City": "Karad",
      "Pincode": "431001",
      "Latitude": 19.076,
      "Longitude": 72.8777,
      "Address": "45 Park Street, Karad, 431001",
      "Clinic": "Chhatrapati Sambhajinagar GP 1",
      "SlotDate": "2026-09-07T19:04:20.553",
      "SlotStartTime": "08:00:00",
      "SlotEndTime": "08:30:00",
      "DistanceInKM": 0.003,
      "FastingRequired": "Fasting Required",
      "IsRoute": "End",
      "OrderStatusID": 5,
      "OrderStatus": "Arrived",
      "Tests": [
        {
          "OrderID": "ORD-102222052",
          "TestID": 10,
          "TestName": "Albumin",
          "SampleTypeName": "Serum",
          "TubeId": 3,
          "TubeContent": "Plain Tube",
          "FastingRequired": "Fasting Not Required"
        }
      ]
    }
  ],
};


