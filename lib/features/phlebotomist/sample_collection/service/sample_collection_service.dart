import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../../../network/api_client.dart';
import '../../../../network/app_error.dart';
import '../../../../network/app_urls.dart';
import '../../../../utils/helper_functions/helper_methods.dart';
import '../../patient_queue/model/order_reject_reasons.dart';
import '../model/pre_collection_checklist.dart';
import '../model/sample_collection_models.dart';

class SampleCollectionService {
  final APIClient _apiClient = Get.find<APIClient>();

  Future<OrderConfirmationDetails> fetchOrderDetails({
    required String orderId,
    required String userId,
  }) async {
    try {
      final url = AppUrls.getSampleRequirements.replaceFirst(
        '{orderId}',
        orderId.toString(),
      );
      final response = await _apiClient.get('$url?userId=$userId');

      final Map<String, dynamic> body = response.data is String
          ? jsonDecode(response.data as String) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;

      if ((body['status'] as String?)?.toLowerCase() != 'success') {
        throw SampleCollectionException(
          body['message'] as String? ?? 'Unable to load order details.',
        );
      }

      final output = body['output'];
      if (output is! Map<String, dynamic>) {
        throw SampleCollectionException(
          'Unexpected response while loading order details.',
        );
      }

      return OrderConfirmationDetails.fromJson(output);
    } on SampleCollectionException {
      rethrow;
    } catch (e) {
      kPrint(e.toString());
      throw SampleCollectionException(
        'Unable to load order details. Please try again.',
        isNetworkError: true,
      );
    }
  }

  Future<List<IncompleteReasonOption>> fetchIncompleteReasons() async {
    try {
      final response = await _apiClient.get(AppUrls.getIncompleteReasons);

      final Map<String, dynamic> body = response.data is String
          ? jsonDecode(response.data as String) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;

      final output = body['output'];
      final List<dynamic> list = output is List ? output : [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(IncompleteReasonOption.fromJson)
          .toList();
    } catch (e) {
      kPrint(e.toString());
      return [];
    }
  }
  Future<List<AssignRejectedReasonOption>> fetchRejectedReasons() async {
    try {
      final response = await _apiClient.get(
        AppUrls.getRejectedReason,
      );

      final Map<String, dynamic> body = response.data is String
          ? jsonDecode(response.data as String) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;

      final output = body['output'];

      final List<dynamic> list = output is List ? output : [];

      return list
          .whereType<Map<String, dynamic>>()
          .map(AssignRejectedReasonOption.fromJson)
          .toList();
    } catch (e) {
      kPrint(e.toString());
      return [];
    }
  }
  Future<List<ComplicationOption>> fetchComplications() async {
    try {
      final response = await _apiClient.get(AppUrls.getComplicationsList);

      final Map<String, dynamic> body = response.data is String
          ? jsonDecode(response.data as String) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;

      final output = body['output'];
      final List<dynamic> list = output is List ? output : [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(ComplicationOption.fromJson)
          .toList();
    } catch (e) {
      kPrint(e.toString());
      return [];
    }
  }

  Future<bool> sendCollectionOtp({
    required String mobileNumber,
    required String userId,
    required String collectionOrderId

  }) async {
    try {
      final body = {
        'MobileNo': mobileNumber,
        'CreatedBy': int.tryParse(userId) ?? 0,
        'SampleCollectionOrderID' : collectionOrderId
      };

      final response = await _apiClient.post(
        AppUrls.sendOTPToPatient,
        data: body,
      );
      final Map<String, dynamic> respBody = response.body;
      kPrint('Send OTP response: $respBody');

      if ((respBody['status'] as String?)?.toLowerCase() != 'success') {
        throw SampleCollectionException(
          respBody['message'] as String? ?? 'Unable to send OTP.',
        );
      }
      return true;
    } on SampleCollectionException {
      rethrow;
    } catch (e) {
      kPrint(e.toString());
      throw SampleCollectionException(
        'Unable to send OTP. Please try again.',
        isNetworkError: true,
      );
    }
  }

  Future<bool> verifyCollectionOtp({
    required String mobileNumber,
    required String otp,
    required String userId,
    required String collectionOrderId
  }) async {
    try {
      final body = {
        'MobileNo': mobileNumber,
        'OTP': otp,
        'VerifyBy': int.tryParse(userId) ?? 0,
        'SampleCollectionOrderID' : collectionOrderId
      };

      final response = await _apiClient.post(
        AppUrls.verifyPatientOTP,
        data: body,
      );
      final Map<String, dynamic> respBody = response.body;
      kPrint('Verify OTP response: $respBody');

      if ((respBody['status'] as String?)?.toLowerCase() != 'success') {
        throw SampleCollectionException(
          respBody['message'] as String? ?? 'Invalid OTP.',
        );
      }
      return true;
    } on SampleCollectionException {
      rethrow;
    } catch (e) {
      kPrint(e.toString());
      throw SampleCollectionException(
        'Unable to verify OTP. Please try again.',
        isNetworkError: true,
      );
    }
  }

  /// Submits the collected samples. Throws [SampleCollectionException]
  /// with [SampleCollectionException.isLisSyncFailure] set when the order
  /// row was inserted but the push to LIS failed — the caller treats that
  /// as a "soft" success, not a hard failure.

  Future<bool> submitSampleCollection(SampleCollectionPayload payload) async {
    try {
      final url = AppUrls.submitSampleCollection.replaceFirst(
        '{orderId}',
        payload.orderId.toString(),
      );
      final response = await _apiClient.post(url, data: payload.toJson());

      final Map<String, dynamic> respBody = response.data is String
          ? jsonDecode(response.data as String) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;

      // New shape: dishaResult is a map with a "status" field that is a
      // 2xx-style HTTP status code (e.g. "201"). Treat 200-299 as success.
      // Anything else — a non-2xx code, or a non-numeric legacy value like
      // "fail insert disha" — is treated as an LIS/Disha sync failure.
      final dishaResultRaw = respBody['dishaResult'];

      bool isLisSuccess;
      String? dishaMessage;

      if (dishaResultRaw is Map<String, dynamic>) {
        final rawStatus = dishaResultRaw['status'];
        final statusCode = rawStatus is int
            ? rawStatus
            : int.tryParse(rawStatus?.toString() ?? '');

        isLisSuccess =
            statusCode != null && statusCode >= 200 && statusCode < 300;
        dishaMessage = dishaResultRaw['message'] as String?;
      } else if (dishaResultRaw is String) {
        // Legacy shape: dishaResult itself is a plain string. Fall back to
        // the old top-level "Dishstatuss" field to judge success/failure.
        dishaMessage = dishaResultRaw;
        final topLevelDishStatus = (respBody['Dishstatuss'] as String?)
            ?.trim()
            .toLowerCase();
        isLisSuccess = topLevelDishStatus != 'fail insert disha';
      } else {
        // No dishaResult at all — nothing to flag, let the top-level
        // `status` field below decide the outcome.
        isLisSuccess = true;
      }

      if (!isLisSuccess) {
        throw SampleCollectionException(
          respBody['message'] as String? ??
              dishaMessage ??
              'Sample collection saved, but the LIS sync failed.',
          isLisSyncFailure: true,
        );
      }

      // Check the LIS/Disha outcome first (above), since the backend can
      // send a top-level status of "Fail" even for this soft-failure case,
      // not just for hard failures where the order row itself wasn't saved.
      final status = (respBody['status'] as String?)?.trim().toLowerCase();
      if (status != 'success') {
        throw SampleCollectionException(
          respBody['message'] as String? ??
              'Unable to submit sample collection.',
        );
      }

      return true;
    } on SampleCollectionException {
      rethrow;
    } on ServerError catch (e) {
      /// http 500 catch it here
      /* body    : {OrderID: ORD-CL3-20260907-09, UserID: 17, OrderStatusCode: COLLECTED, bagId: 37, SessionID: 15, TubeCount: 1, Notes: , CollectedAt: 2026-09-07T12:34:24.147985Z, SampleCollectionDetails: [{SampleTypeID: 2, BarcodeNo: Ac24242}], SampleCollectionComplications: [{ComplicationID: 1, Status: true}, {ComplicationID: 2, Status: false}, {ComplicationID: 3, Status: true}, {ComplicationID: 4, Status: false}, {ComplicationID: 5, Status: true}, {ComplicationID: 6, Status: false}], IncompleteTests: []}
   headers : {Content-Type: application/json, Authorization: Bearer ***}
       status  : 500 (744ms)
   response: {Dishstatuss: Fail Insert Disha, status: Fail, message: DISHA registration succeeded, but saving DISHA details failed, dishaResult: Response: }*/

      Map<String, dynamic>? respBody;
      final raw = e.cause is DioException
          ? (e.cause as DioException).response?.data
          : null;
      if (raw is String) {
        try {
          respBody = jsonDecode(raw) as Map<String, dynamic>;
        } catch (_) {}
      } else if (raw is Map<String, dynamic>) {
        respBody = raw;
      }

      final dishaResultRaw = respBody?['dishaResult'];
      final topLevelDishStatus = (respBody?['Dishstatuss'] as String?)
          ?.trim()
          .toLowerCase();
      final looksLikeDishaFailure =
          dishaResultRaw != null || topLevelDishStatus == 'fail insert disha';

      if (looksLikeDishaFailure) {
        throw SampleCollectionException(
          (respBody?['message'] as String?) ?? e.message,
          isLisSyncFailure: true,
        );
      }
      rethrow; // genuine server error unrelated to Disha — keep old behavior
    } catch (e) {
      kPrint(e.toString());
      throw SampleCollectionException(
        'Unable to submit sample collection. Please try again.',
        isNetworkError: true,
      );
    }
  }

  Future<bool> resubmitToDisha({
    required String orderId,
    required String userId,
  }) async {
    try {
      final url = AppUrls.dishaSampleCollectionSync.replaceFirst(
        '{orderId}',
        orderId,
      );
      final reqBody = {'orderId ': orderId, 'userId': userId};
      final response = await _apiClient.post(url, data: reqBody);

      final Map<String, dynamic> body = response.data is String
          ? jsonDecode(response.data as String) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;

      final status = (body['status'] as String?)?.trim().toLowerCase();
      if (status == 'fail insert disha') {
        throw SampleCollectionException(
          body['message'] as String? ?? 'Disha sync is still pending.',
        );
      }
      if (status != 'success') {
        throw SampleCollectionException(
          body['message'] as String? ?? 'Disha sync is still pending.',
        );
      }
      return true;
    } on SampleCollectionException {
      rethrow;
    } catch (e) {
      kPrint(e.toString());
      throw SampleCollectionException(
        'Unable to reach Disha right now. Please try again shortly.',
        isNetworkError: true,
      );
    }
  }

  Future<bool> reschedule({
    required String orderId,
    required int userId,
    required int createdBy,
    required DateTime appointmentDate,
    required int slotId,
    int? rescheduleReasonId,
  }) async {
    final body = {
      'OrderID': orderId,
      'usreID': userId,
      'AppoinmentDate': appointmentDate.toIso8601String(),
      'SlotID': slotId,
      'RescheduleReasoneID': rescheduleReasonId ?? 0,
      'CreatedBy': createdBy,
    };

    try {
      final response = await _apiClient.post(
        AppUrls.appointmentRescheduled,
        data: body,
      );
      final Map<String, dynamic> respBody = response.data is String
          ? jsonDecode(response.data as String) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;

      final isSuccess =
          (respBody['status'] as String?)?.toLowerCase() == 'success';

      if (!isSuccess) {
        final message = (respBody['message'] as String?)?.trim() ?? '';
        throw SampleCollectionException(
          message.isEmpty ? 'Unable to reschedule this visit.' : message,
        );
      }
      return true;
    } on SampleCollectionException {
      rethrow;
    } catch (_) {
      throw SampleCollectionException(
        'Unable to reschedule this visit. Please try again.',
        isNetworkError: true,
      );
    }
  }

  /// Checks live availability of a barcode before it's accepted onto a sample.
  /// Returns true when the barcode is free to use, false when it's already
  /// taken (409 / FAILED). Throws on genuine network/parsing failure.
  Future<bool> checkBarcodeAvailability(String barcode) async {
    try {
      final reqBody = {'barcode': barcode};
      final response = await _apiClient.post(
        AppUrls.checkBarcodeAvailability,
        data: reqBody,
      );

      final Map<String, dynamic> body = response.data is String
          ? jsonDecode(response.data as String) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;

      final statusCode = body['statusCode'] is int
          ? body['statusCode'] as int
          : int.tryParse(body['statusCode']?.toString() ?? '');
      final status = (body['status'] as String?)?.trim().toUpperCase();

      if (statusCode == 200 || status == 'SUCCESS') return true;
      if (statusCode == 409 || status == 'FAILED') return false;

      // Unexpected shape — treat as a soft failure with the server's message.
      throw SampleCollectionException(
        body['message'] as String? ?? 'Unable to verify barcode.',
      );
    } on SampleCollectionException {
      rethrow;
    } catch (e) {
      kPrint(e.toString());
      throw SampleCollectionException(
        'Unable to verify barcode. Please try again.',
        isNetworkError: true,
      );
    }
  }
  Future<List<ChecklistItem>> fetchCollectionChecklist({
    required String orderId,
    required String userId,
  }) async {
    try {
      final reqBody = {
        'orderID' : orderId,
        'userID' : userId,
      };
      final response = await _apiClient.post(
        AppUrls.collectionChecklist,
        data: reqBody,
      );

      final Map<String, dynamic> body = response.data is String
          ? jsonDecode(response.data as String) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;

      if ((body['status'] as String?)?.toLowerCase() != 'success') {
        throw SampleCollectionException(
          body['message'] as String? ?? 'Unable to load checklist.',
        );
      }

      final output = body['output'];
      final List<dynamic> list = output is List ? output : [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(ChecklistItem.fromJson)
          .toList();
    } on SampleCollectionException {
      rethrow;
    } catch (e) {
      kPrint(e.toString());
      throw SampleCollectionException(
        'Unable to load checklist. Please try again.',
        isNetworkError: true,
      );
    }
  }

  Future<bool> submitCollectionChecklist({
    required String orderId,
    required int userId,
    required int createdBy,
    required List<ChecklistAnswer> answers,
  }) async {
    try {
      final body = {
        'OrderID': orderId,
        'UserID': userId,
        'ChecklistDetails': answers.map((a) => a.toJson()).toList(),
        'CreatedBy': createdBy,
      };
      final url = AppUrls.insertCollectionCheckList.replaceFirst('{order-id}', orderId);

      final response = await _apiClient.post(
        url,
        data: body,
      );

      final Map<String, dynamic> respBody = response.data is String
          ? jsonDecode(response.data as String) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;

      if ((respBody['status'] as String?)?.toLowerCase() != 'success') {
        throw SampleCollectionException(
          respBody['message'] as String? ?? 'Unable to save checklist.',
        );
      }
      return true;
    } on SampleCollectionException {
      rethrow;
    } catch (e) {
      kPrint(e.toString());
      throw SampleCollectionException(
        'Unable to save checklist. Please try again.',
        isNetworkError: true,
      );
    }
  }
}

final dummyOrder = {
  "status": "Success",
  "message": "Sample requirements details",
  "output": {
    "orderId": "ORD-40111",
    "priority": "Low",
    "slotDate": "9/5/2026 12:31:38 PM",
    "slotStartTime": "08:00:00",
    "slotEndTime": "08:30:00",
    "slotDateTime": "5 Sep 2026 8:00AM - 8:30AM",
    "patient": {
      "patientId": "PAT-40111",
      "name": "Ms. Manisha K. Pawar",
      "age": "46 Years",
      "gender": "Female",
      "photoUrl": ""
    },
    "fastingRequired": false,
    "fastingNote": "Cholesterol LDL Direct-Fasting required for 8-12 hours before sample collection.,Triglycerides-Fasting required for 8-12 hours before sample collection.,Cholesterol HDL Direct-Fasting required for 8-12 hours before sample collection.,Glucose (Blood Sugar), Fasting-Fasting required for 8-12 hours before sample collection.,Lipid Profile-Fasting required for 8-12 hours before sample collection.",
    "specialInstructions": [
      {
        "testId": 1,
        "testSpecialInstId": 1,
        "specialInstruction": "Inform the laboratory if taking thyroid medication or biotin supplements. Follow laboratory instructions regarding biotin before sample collection."
      },
      {
        "testId": 13,
        "testSpecialInstId": 2,
        "specialInstruction": "Inform the laboratory if taking thyroid medication or biotin supplements. Follow laboratory instructions regarding biotin before sample collection."
      },
      {
        "testId": 2,
        "testSpecialInstId": 3,
        "specialInstruction": "Inform the laboratory if taking thyroid medication or biotin supplements. Follow laboratory instructions regarding biotin before sample collection."
      },
      {
        "testId": 14,
        "testSpecialInstId": 4,
        "specialInstruction": "Inform the laboratory if taking thyroid medication or biotin supplements. Follow laboratory instructions regarding biotin before sample collection."
      },
      {
        "testId": 54,
        "testSpecialInstId": 5,
        "specialInstruction": "Follow the laboratory fasting instructions before sample collection. Inform the laboratory about current medications or supplements."
      },
      {
        "testId": 46,
        "testSpecialInstId": 6,
        "specialInstruction": "Fasting is required. Follow the laboratory fasting instructions before sample collection."
      },
      {
        "testId": 53,
        "testSpecialInstId": 7,
        "specialInstruction": "Follow the laboratory fasting instructions before sample collection."
      },
      {
        "testId": 57,
        "testSpecialInstId": 8,
        "specialInstruction": "Follow the laboratory instructions regarding fasting before sample collection."
      },
      {
        "testId": 49,
        "testSpecialInstId": 9,
        "specialInstruction": "Follow the laboratory fasting instructions before sample collection. Inform the laboratory about current medications or supplements."
      },
      {
        "testId": 72,
        "testSpecialInstId": 10,
        "specialInstruction": "Follow the laboratory fasting instructions before sample collection. Inform the laboratory about current medications or supplements."
      },
      {
        "testId": 59,
        "testSpecialInstId": 11,
        "specialInstruction": "Follow the laboratory fasting instructions before sample collection. Inform the laboratory about current medications or supplements."
      },
      {
        "testId": 64,
        "testSpecialInstId": 12,
        "specialInstruction": "Follow the laboratory fasting instructions before sample collection."
      },
      {
        "testId": 82,
        "testSpecialInstId": 13,
        "specialInstruction": "Sample collection is preferably performed around 8:00 AM. Follow the laboratory instructions regarding timing and medications."
      },
      {
        "testId": 50,
        "testSpecialInstId": 14,
        "specialInstruction": "Collect a clean-catch midstream urine sample in the designated sterile container. Avoid contamination of the sample."
      },
      {
        "testId": 71,
        "testSpecialInstId": 15,
        "specialInstruction": "Collect the urine sample in the designated urine container. Follow the laboratory instructions for sample collection and handling."
      },
      {
        "testId": 73,
        "testSpecialInstId": 16,
        "specialInstruction": "Inform the laboratory about current anticoagulant medication. Ensure the sample is collected and handled according to the laboratory coagulation protocol."
      },
      {
        "testId": 92,
        "testSpecialInstId": 17,
        "specialInstruction": "Inform the laboratory about current anticoagulant medication. Ensure the sample is collected and handled according to the laboratory coagulation protocol."
      },
      {
        "testId": 95,
        "testSpecialInstId": 20,
        "specialInstruction": "Collect the blood culture sample using the required blood culture collection procedure and maintain strict aseptic technique."
      },
      {
        "testId": 100,
        "testSpecialInstId": 21,
        "specialInstruction": "Collect the specimen using the appropriate sterile collection technique and transport it according to laboratory protocol."
      },
      {
        "testId": 20,
        "testSpecialInstId": 22,
        "specialInstruction": "Collect and prepare the specimen according to the laboratory Gram stain collection and handling protocol."
      },
      {
        "testId": 76,
        "testSpecialInstId": 23,
        "specialInstruction": "Follow the laboratory instructions for specimen collection and handling before testing."
      },
      {
        "testId": 77,
        "testSpecialInstId": 24,
        "specialInstruction": "Collect and prepare the blood sample according to the laboratory peripheral smear protocol."
      },
      {
        "testId": 79,
        "testSpecialInstId": 25,
        "specialInstruction": "Collect the blood sample according to the laboratory malaria smear collection and preparation protocol."
      },
      {
        "testId": 78,
        "testSpecialInstId": 26,
        "specialInstruction": "Follow the laboratory instructions for malaria antigen specimen collection and handling."
      },
      {
        "testId": 87,
        "testSpecialInstId": 27,
        "specialInstruction": "Follow the laboratory procedure for bleeding time testing and ensure the patient is prepared according to protocol."
      }
    ],
    "sampleRequirements": [
      {
        "sampleTypeId": 1,
        "sampleType": "Blood",
        "volumeRequiredMl": "2.00 mL",
        "tests": [
          {
            "testId": 95,
            "testCode": "WL0003065",
            "testName": "AEROBIC BLOOD CULTURE",
            "tubeTypes": []
          },
          {
            "testId": 87,
            "testCode": "WLH001503",
            "testName": "Bleeding Time(BT)",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          }
        ]
      },
      {
        "sampleTypeId": 16,
        "sampleType": "Citrated Plasma",
        "volumeRequiredMl": "2.00 - 5.00 mL",
        "tests": [
          {
            "testId": 92,
            "testCode": "HEM002",
            "testName": "APTT Activated Partial Thromboplastin Time",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          }
        ]
      },
      {
        "sampleTypeId": 10,
        "sampleType": "EDTA Whole Blood",
        "volumeRequiredMl": "2.00 - 5.00 mL",
        "tests": [
          {
            "testId": 48,
            "testCode": "HEM004",
            "testName": "Blood Group Rh Type",
            "tubeTypes": [
              {
                "tubeTypeId": 1,
                "tubeType": "EDTA Tube"
              },
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 93,
            "testCode": "HEM005",
            "testName": "CBC (Haemogram)",
            "tubeTypes": [
              {
                "tubeTypeId": 1,
                "tubeType": "EDTA Tube"
              },
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 43,
            "testCode": "HEM008",
            "testName": "ESR - Erythrocyte Sedimentation Rate",
            "tubeTypes": [
              {
                "tubeTypeId": 1,
                "tubeType": "EDTA Tube"
              }
            ]
          },
          {
            "testId": 69,
            "testCode": "HEM011",
            "testName": "HbA1C - Glycated Haemoglobin",
            "tubeTypes": [
              {
                "tubeTypeId": 1,
                "tubeType": "EDTA Tube"
              }
            ]
          },
          {
            "testId": 78,
            "testCode": "HEM013",
            "testName": "Malaria Antigen (Vivax & Falciparum) Detection - Rapid",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 79,
            "testCode": "HEM012",
            "testName": "Malaria Parasite Detection by Smear examination",
            "tubeTypes": [
              {
                "tubeTypeId": 1,
                "tubeType": "EDTA Tube"
              }
            ]
          },
          {
            "testId": 77,
            "testCode": "HEM014",
            "testName": "Peripheral smear examination",
            "tubeTypes": [
              {
                "tubeTypeId": 1,
                "tubeType": "EDTA Tube"
              }
            ]
          }
        ]
      },
      {
        "sampleTypeId": 3,
        "sampleType": "Plasma",
        "volumeRequiredMl": "10.00 - 20.00 mL",
        "tests": [
          {
            "testId": 53,
            "testCode": "BIO023",
            "testName": "Glucose (Blood Sugar), PP (Post Prandial)",
            "tubeTypes": [
              {
                "tubeTypeId": 1,
                "tubeType": "EDTA Tube"
              }
            ]
          },
          {
            "testId": 73,
            "testCode": "HEM016",
            "testName": "Prothrombin Time (PT)",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 81,
            "testCode": "IMM072",
            "testName": "Troponin-T",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          }
        ]
      },
      {
        "sampleTypeId": 12,
        "sampleType": "Plasma F",
        "volumeRequiredMl": "2.00 - 5.00 mL",
        "tests": [
          {
            "testId": 46,
            "testCode": "BIO022",
            "testName": "Glucose (Blood Sugar), Fasting",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          }
        ]
      },
      {
        "sampleTypeId": 11,
        "sampleType": "Plasma R",
        "volumeRequiredMl": "2.00 - 5.00 mL",
        "tests": [
          {
            "testId": 57,
            "testCode": "BIO024",
            "testName": "Glucose (Blood Sugar), Random",
            "tubeTypes": [
              {
                "tubeTypeId": 1,
                "tubeType": "EDTA Tube"
              }
            ]
          }
        ]
      },
      {
        "sampleTypeId": 2,
        "sampleType": "Serum",
        "volumeRequiredMl": "10.00 - 20.00 mL",
        "tests": [
          {
            "testId": 27,
            "testCode": "WLH001502",
            "testName": "25-OH Vitamin D",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 10,
            "testCode": "BIO002",
            "testName": "Albumin",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 23,
            "testCode": "BIO003",
            "testName": "Alkaline Phosphatase",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 19,
            "testCode": "IMM011",
            "testName": "Alpha Feto Protein (AFP)",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 3,
            "testCode": "BIO004",
            "testName": "Amylase",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 90,
            "testCode": "WLH002376",
            "testName": "ANA - ANTI NUCLEAR ANTIBODIES BY IF",
            "tubeTypes": []
          },
          {
            "testId": 86,
            "testCode": "IMM017",
            "testName": "Antibody Cyclic Citrullinated Peptide (Anti CCP)",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 55,
            "testCode": "BIO005",
            "testName": "Bilirubin - Direct",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 67,
            "testCode": "BIO006",
            "testName": "Bilirubin - Indirect",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 62,
            "testCode": "BIO007",
            "testName": "Bilirubin - Total",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 28,
            "testCode": "BIO008",
            "testName": "BUN (Blood Urea Nitrogen)",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 99,
            "testCode": "WLH001646",
            "testName": "C-REACTIVE PROTEINS (QUANTITATIVE)-",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 33,
            "testCode": "WLH001529",
            "testName": "CA 15-3",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 36,
            "testCode": "WLH001530",
            "testName": "CA 19.9",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 61,
            "testCode": "BIO011",
            "testName": "Calcium Total",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 39,
            "testCode": "IMM024",
            "testName": "Carcino Embryonic Antigen (CEA)",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 63,
            "testCode": "BIO012",
            "testName": "Chlorides",
            "tubeTypes": [
              {
                "tubeTypeId": 1,
                "tubeType": "EDTA Tube"
              }
            ]
          },
          {
            "testId": 94,
            "testCode": "BIO013",
            "testName": "Cholesterol - Total",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 44,
            "testCode": "BIO014",
            "testName": "Cholesterol HDL Direct",
            "tubeTypes": [
              {
                "tubeTypeId": 1,
                "tubeType": "EDTA Tube"
              }
            ]
          },
          {
            "testId": 17,
            "testCode": "BIO015",
            "testName": "Cholesterol LDL Direct",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 82,
            "testCode": "IMM030",
            "testName": "Cortisol (8AM)",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 9,
            "testCode": "BIO058",
            "testName": "Creatinine",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 85,
            "testCode": "SER004",
            "testName": "Dengue (NS1) Antigen - Rapid",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 75,
            "testCode": "SER005",
            "testName": "Dengue IGG Rapid",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 68,
            "testCode": "SER006",
            "testName": "Dengue IGM Rapid",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 41,
            "testCode": "WLE00844",
            "testName": "e-GFR With Creatinine",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 64,
            "testCode": "PRF001",
            "testName": "Electrolytes",
            "tubeTypes": [
              {
                "tubeTypeId": 1,
                "tubeType": "EDTA Tube"
              }
            ]
          },
          {
            "testId": 12,
            "testCode": "IMM034",
            "testName": "Ferritin",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 8,
            "testCode": "IMM110",
            "testName": "Folic acid",
            "tubeTypes": []
          },
          {
            "testId": 13,
            "testCode": "IMM035",
            "testName": "Free T3",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 1,
            "testCode": "IMM036",
            "testName": "Free T4",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 7,
            "testCode": "IMM008",
            "testName": "Free testosterone",
            "tubeTypes": []
          },
          {
            "testId": 31,
            "testCode": "WLH001636",
            "testName": "FSH",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 45,
            "testCode": "BIO020",
            "testName": "Gamma Glutamyl Transferase Test (GGT)",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 56,
            "testCode": "WLH002292",
            "testName": "HbSag- Rapid",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 18,
            "testCode": "IMM087",
            "testName": "HS-Troponin-I",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 96,
            "testCode": "IMM047",
            "testName": "Immunoglobulin E (IgE)",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 83,
            "testCode": "BIO035",
            "testName": "Iron",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 72,
            "testCode": "PRF005",
            "testName": "Iron Studies (Iron, TIBC, TS %)",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 66,
            "testCode": "BIO036",
            "testName": "LDH (Lactate Dehydrogenase)",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 38,
            "testCode": "IMM053",
            "testName": "LH-Luteinizing Hormone",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 49,
            "testCode": "PRF006",
            "testName": "Lipid Profile",
            "tubeTypes": [
              {
                "tubeTypeId": 1,
                "tubeType": "EDTA Tube"
              },
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 59,
            "testCode": "PRF007",
            "testName": "Liver Function Test (LFT)",
            "tubeTypes": [
              {
                "tubeTypeId": 1,
                "tubeType": "EDTA Tube"
              },
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 4,
            "testCode": "BIO038",
            "testName": "Magnesium",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 37,
            "testCode": "WLH002294",
            "testName": "N-terminal pro-B type Natriuretic Peptide",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 58,
            "testCode": "BIO041",
            "testName": "Phosphorus",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 52,
            "testCode": "BIO042",
            "testName": "Potassium ISE",
            "tubeTypes": [
              {
                "tubeTypeId": 1,
                "tubeType": "EDTA Tube"
              }
            ]
          },
          {
            "testId": 34,
            "testCode": "IMM057",
            "testName": "Progesterone (P4)",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 35,
            "testCode": "IMM058",
            "testName": "Prolactin (PRL)",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 80,
            "testCode": "BIO045",
            "testName": "Protein - Total",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 51,
            "testCode": "WLH000178",
            "testName": "Renal Function Test (KFT)",
            "tubeTypes": [
              {
                "tubeTypeId": 1,
                "tubeType": "EDTA Tube"
              },
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 70,
            "testCode": "SER015",
            "testName": "Rheumatoid Arthritis Factor (RA)",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 24,
            "testCode": "BIO046",
            "testName": "SGOT / AST (Aspartate Transaminase)",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 47,
            "testCode": "BIO047",
            "testName": "SGPT / ALT (Alanine Aminotransferase)",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 60,
            "testCode": "BIO048",
            "testName": "Sodium ISE",
            "tubeTypes": [
              {
                "tubeTypeId": 1,
                "tubeType": "EDTA Tube"
              }
            ]
          },
          {
            "testId": 2,
            "testCode": "IMM065",
            "testName": "T3",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 54,
            "testCode": "PRF009",
            "testName": "T3, T4, TSH (TFT)",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 14,
            "testCode": "IMM066",
            "testName": "T4",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 40,
            "testCode": "IMM067",
            "testName": "Testosterone Total",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 25,
            "testCode": "SM000163",
            "testName": "Total Beta Human Chorionic Gonadotropin",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 84,
            "testCode": "WLH001663",
            "testName": "Total IgE",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 26,
            "testCode": "BIO053",
            "testName": "Triglycerides",
            "tubeTypes": [
              {
                "tubeTypeId": 1,
                "tubeType": "EDTA Tube"
              },
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 88,
            "testCode": "WLH002332",
            "testName": "Troponin - I Qualitative",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 74,
            "testCode": "WLH001625",
            "testName": "Troponin-T Quantitative",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 76,
            "testCode": "WLH002372",
            "testName": "Typhi Dot IgM",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 32,
            "testCode": "BIO054",
            "testName": "Urea",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 15,
            "testCode": "BIO055",
            "testName": "Uric Acid",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 65,
            "testCode": "IMM073",
            "testName": "Vitamin B12 (Cyanocobalamin)",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 98,
            "testCode": "SER018",
            "testName": "Widal (Slide Method)",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          }
        ]
      },
      {
        "sampleTypeId": 7,
        "sampleType": "Sputum",
        "volumeRequiredMl": "2.00 - 10.00 mL",
        "tests": [
          {
            "testId": 20,
            "testCode": "WLH002127",
            "testName": "Gram Stain",
            "tubeTypes": []
          }
        ]
      },
      {
        "sampleTypeId": 6,
        "sampleType": "Swab",
        "volumeRequiredMl": "2.00 - 5.00 mL",
        "tests": [
          {
            "testId": 100,
            "testCode": "WLH002153",
            "testName": "E.T. SECRETION CULTURE",
            "tubeTypes": []
          }
        ]
      },
      {
        "sampleTypeId": 4,
        "sampleType": "Urine",
        "volumeRequiredMl": "10.00 - 20.00 mL",
        "tests": [
          {
            "testId": 71,
            "testCode": "CLP007",
            "testName": "Pregnancy test-Urine (UPT)",
            "tubeTypes": [
              {
                "tubeTypeId": 2,
                "tubeType": "Plain Tube"
              }
            ]
          },
          {
            "testId": 50,
            "testCode": "CLP010",
            "testName": "Routine Examination Urine",
            "tubeTypes": [
              {
                "tubeTypeId": 3,
                "tubeType": "Urine Container"
              }
            ]
          }
        ]
      }
    ],
    "totalSampleTypes": 10,
    "totalTestCountReceived": 87,
    "MobileNumber": "9876530011",
    "IsOTPverify": "Not Send",
    "SampleCollectionOrderID": 83
  }
};