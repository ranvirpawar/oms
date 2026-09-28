import 'package:get/get.dart' hide SnackPosition;

import '../../../network/api_client.dart';
import '../../../network/app_urls.dart';
import '../../../utils/ui_designs/liquid_snackbar.dart';

class ProfileService {
  final APIClient _apiClient = Get.find<APIClient>();

  /// Send OTP to [newMobileNo] for profile mobile-number update.
  /// Returns true when the API responds with status == "SUCCESS".
  Future<bool> sendProfileUpdateOtp({
    required int userId,
    required String newMobileNo,
  }) async {
    try {
      final response = await _apiClient.post(
        AppUrls.sendUserProfileUpdateOtp,
        data: {'UserID': userId, 'NewMobileNo': newMobileNo},
      );

      final data = response.body;
      if ((data['status'] as String?)?.toUpperCase() == 'SUCCESS') {
        return true;
      } else {
        LiquidSnack.error(
          data['message'] ?? 'Could not send OTP. Please try again.',
          position: SnackPosition.top,
        );
        return false;
      }
    } catch (e) {
      LiquidSnack.error(
        'Something went wrong. Please try later.',
        position: SnackPosition.top,
      );
      rethrow;
    }
  }

  /// Verify the OTP entered by the user.
  /// Returns true when the API responds with status == "SUCCESS".
  Future<bool> verifyProfileUpdateOtp({
    required int userId,
    required String mobileNo,
    required String otp,
  }) async {
    try {
      final response = await _apiClient.post(
        AppUrls.verifyUserProfileUpdateOtp,
        data: {'UserID': userId, 'MobileNo': mobileNo, 'OTP': otp},
      );

      final data = response.body;
      if ((data['status'] as String?)?.toUpperCase() == 'SUCCESS') {
        return true;
      } else {
        LiquidSnack.error(
          data['message'] ?? 'Incorrect OTP. Please try again.',
          position: SnackPosition.top,
        );
        return false;
      }
    } catch (e) {
      LiquidSnack.error(
        'Something went wrong. Please try later.',
        position: SnackPosition.top,
      );
      rethrow;
    }
  }

  /// Updates the user's name fields and mobile number via UpdateUserProfile.
  /// Returns true on SUCCESS, false on any API-level failure (error shown via snackbar).
  Future<bool> updateUserProfile({
    required int userId,
    required String firstName,
    required String midName,
    required String lastName,
    required String newMobileNo,
  }) async {
    try {
      final response = await _apiClient.post(
        AppUrls.updateUserProfile,
        data: {
          'UserID': userId,
          'FirstName': firstName,
          'MidName': midName,
          'LastName': lastName,
          'NewMobileNo': newMobileNo,
        },
      );

      final data = response.body;
      if ((data['status'] as String?)?.toUpperCase() == 'SUCCESS') {
        return true;
      } else {
        LiquidSnack.error(
          data['message'] ?? 'Profile update failed. Please try again.',
          position: SnackPosition.top,
        );
        return false;
      }
    } catch (e) {
      LiquidSnack.error(
        'Something went wrong. Please try later.',
        position: SnackPosition.top,
      );
      rethrow;
    }
  }
}
