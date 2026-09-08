

import 'dart:convert';

import 'package:get/get.dart';

import '../../../../network/api_client.dart';
import '../../../../network/app_urls.dart';
import '../../../../utils/helper_functions/helper_methods.dart';
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
        'Unable to load order details. Please check your connection and try again.',
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
  }) async {
    try {
      final body = {
        'MobileNo': mobileNumber,
        'CreatedBy': int.tryParse(userId) ?? 0,
      };

      final response = await _apiClient.post(AppUrls.sendOTPToPatient, data: body);
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
        'Unable to send OTP. Please check your connection and try again.',
        isNetworkError: true,
      );
    }
  }

  Future<bool> verifyCollectionOtp({
    required String mobileNumber,
    required String otp,
    required String userId,
  }) async {
    try {
      final body = {
        'MobileNo': mobileNumber,
        'OTP': otp,
        'VerifyBy': int.tryParse(userId) ?? 0,
      };

      final response = await _apiClient.post(AppUrls.verifyPatientOTP, data: body);
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
        'Unable to verify OTP. Please check your connection and try again.',
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

        isLisSuccess = statusCode != null && statusCode >= 200 && statusCode < 300;
        dishaMessage = dishaResultRaw['message'] as String?;
      } else if (dishaResultRaw is String) {
        // Legacy shape: dishaResult itself is a plain string. Fall back to
        // the old top-level "Dishstatuss" field to judge success/failure.
        dishaMessage = dishaResultRaw;
        final topLevelDishStatus =
        (respBody['Dishstatuss'] as String?)?.trim().toLowerCase();
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
    } catch (e) {
      kPrint(e.toString());
      throw SampleCollectionException(
        'Unable to submit sample collection. Please check your connection and try again.',
        isNetworkError: true,
      );
    }
  }




  Future<bool> resubmitToDisha({required String orderId, required String userId}) async {
    try {
      final url = AppUrls.dishaSampleCollectionSync.replaceFirst(
        '{orderId}',
        orderId,
      );
      final reqBody = {
        'orderId ' :orderId,
        'userId': userId
      };
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
        'Unable to reschedule this visit. Please check your connection and try again.',
        isNetworkError: true,
      );
    }
  }
}