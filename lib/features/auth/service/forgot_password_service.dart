import 'package:get/get.dart';

import '../../../network/api_client.dart';
import '../../../network/app_urls.dart';
import '../../../utils/ui_designs/liquid_snackbar.dart';


class ForgotPasswordService {
  final APIClient _apiClient = Get.find<APIClient>();

  /// Phase 1 — Send OTP to given mobile number.
  /// Returns true on success, false on API-level failure.
  Future<bool> sendOtp(String mobileNo) async {
    try {
      final response = await _apiClient.post(
        AppUrls.forgotPassword,
        data: {'MobileNo': mobileNo},
      );

      // final data = response['data'];
      final data = response.body;
      if (data['status'] == 'Success') {
        return true;
      } else {
        LiquidSnack.error(data['message'] ?? 'Could not send OTP');
        return false;
      }
    } catch (e) {
      LiquidSnack.error('Something went wrong. Please try later.');
      rethrow;
    }
  }

  /// Phase 2 — Reset password using OTP + new password.
  /// Returns true on success, false on API-level failure.
  Future<bool> resetPassword({
    required String mobileNo,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.post(
        AppUrls.resetPassword,
        data: {
          'MobileNo': mobileNo,
          'Otp': otp,
          'Password': newPassword,
        },
      );

      // final data = response['data'];
      final data = response.body;
      if (data['status'] == 'Success') {
        return true;
      } else {
        LiquidSnack.error(data['message'] ?? 'Reset failed. Check your OTP.');
        return false;
      }
    } catch (e) {
      LiquidSnack.error('Something went wrong. Please try later.');
      rethrow;
    }
  }
}
