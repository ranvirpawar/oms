

import 'dart:convert';

import 'package:get/get.dart';

import '../../../../network/api_client.dart';
import '../../../../network/app_urls.dart';
import '../../../../utils/helper_functions/helper_methods.dart';
import '../model/sample_collection_models.dart';

class SampleCollectionException implements Exception {
  final String message;
  final bool isNetworkError;

  SampleCollectionException(this.message, {this.isNetworkError = false});

  @override
  String toString() => message;
}

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
          // 'TESTmob123'
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
  /// Reasons available when a sample could not be collected.
  Future<List<IncompleteReasonOption>> fetchIncompleteReasons() async {
    try {
      final response = await _apiClient.get(

        AppUrls.getIncompleteReasons,
      );

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

  /// List of complications the collector can flag (checked against
  /// yes/no during collection).
  Future<List<ComplicationOption>> fetchComplications() async {
    try {
      final response = await _apiClient.get(
        AppUrls.getComplicationsList,
      );

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
      // Non-fatal: collection can still proceed without complications data.
      return [];
    }
  }

  // ---------------------------------------------------------------------
  // OTP — PLACEHOLDER ONLY. The send/verify OTP endpoints are not
  // available yet. Replace the bodies below with real _apiClient calls
  // (and add the corresponding entries to AppUrls) once they exist.
  // Nothing else in this service is mocked.
  // ---------------------------------------------------------------------
  /*Future<bool> sendCollectionOtp({
    required String mobileNumber,
    required String userId,
  }) async {
    final body =
    {
      'MobileNo': mobileNumber,
      'CreatedBy': userId,
    }
    ;
    // final response = await _apiClient.post(AppUrls.sendOTPToPatient, data:  body );
    await Future.delayed(const Duration(milliseconds: 900));
    kPrint('[MOCK] OTP sent for order $mobileNumber (userId=$userId)');
    return true;
  }

  Future<bool> verifyCollectionOtp({
    required String orderId,
    required String otp,
  }) async {
    // final response = await _apiClient.post(AppUrls.verifyPatientOTP);
    await Future.delayed(const Duration(milliseconds: 900));
    kPrint('[MOCK] OTP verify attempted for order $orderId, otp=$otp');

    return otp.trim().length == 4;
  }*/
  Future<bool> sendCollectionOtp({
    required String mobileNumber,
    required String userId,
  }) async {
    try {
      final body = {
        'MobileNo': mobileNumber,
        'CreatedBy': int.tryParse(userId) ?? 0,
      };

      final response = await _apiClient.post(
        AppUrls.sendOTPToPatient,
        data: body,
      );

      final Map<String, dynamic> respBody = response.body;

      kPrint('Send OTP response: $respBody');

      if ((respBody['status'] as String?)?.toLowerCase() != 'success') {
        throw SampleCollectionException(
          respBody['message'] as String? ??
              'Unable to send OTP.',
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

      final response = await _apiClient.post(
        AppUrls.verifyPatientOTP,
        data: body,
      );

      final Map<String, dynamic> respBody = response.body;

      kPrint('Verify OTP response: $respBody');

      if ((respBody['status'] as String?)?.toLowerCase() != 'success') {
        throw SampleCollectionException(
          respBody['message'] as String? ??
              'Invalid OTP.',
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

  Future<bool> submitSampleCollection(SampleCollectionPayload payload) async {
    try {

      // rather than reusing getSampleRequirements for the POST.
      final url = AppUrls.submitSampleCollection.replaceFirst(
        '{orderId}',
        payload.orderId.toString(),
      );
      final response = await _apiClient.post(
        url,
        data: payload.toJson(),
      );
      final Map<String, dynamic> respBody = response.data is String
          ? jsonDecode(response.data as String) as Map<String, dynamic>
          : response.data as Map<String, dynamic>;

      if ((respBody['status'] as String?)?.toLowerCase() != 'success') {
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
}