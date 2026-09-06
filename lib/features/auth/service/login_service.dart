import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/services/snackbar_service.dart';

import '../../../network/api_client.dart';
import '../../../network/app_urls.dart';
import '../../../utils/helper_functions/helper_methods.dart';
import '../model/login_response_model.dart';


import '../model/profile_model.dart';

class LoginService {
  final APIClient apiClient = Get.find<APIClient>();

  Future<LoginResponseModel> login(String username, String password) async {
    try {
      final url = AppUrls.login;
      final params = {
        'UserEmail': username,
        'Password': password,
      };

      final response = await apiClient.post(url, data: params);
      final data = response.body;

      if (data['status'] == 'Success') {
        final loginResponse = LoginResponseModel.fromJson(data);
        return loginResponse;
      } else {
        return LoginResponseModel(
          status: 'Fail',
          message: data['message'] ?? 'Login failed',
        );
      }
    } catch (e) {
      SnackBarService.to
          .showMessage(message: 'Something went wrong please try later');
      rethrow;
    }
  }

  /// Step 2 of the two-factor login flow. Verifies the 4-digit OTP
  /// against the userId returned by [login], and — on success —
  /// completes the login (same response shape as [login]'s success
  /// case: token/session + user profile).
  Future<LoginResponseModel> verifyLoginOtp({
    required int userId,
    required String otp,
  }) async {
    try {
      final url = AppUrls.verifyLoginOtp; // TODO: add this to AppUrls
      final params = {
        'UserId': userId,
        'Otp': otp,
      };

      kPrint('Verifying OTP for userId: $userId');

      final response = await apiClient.post(url, data: params);
      final data = response.body;

      HelperMethods.printLongString(data.toString());

      if (data['status'] == 'Success') {
        return LoginResponseModel.fromJson(data);
      } else {
        return LoginResponseModel(
          status: 'Fail',
          message: data['message'] ?? 'Incorrect OTP. Please try again.',
        );
      }
    } catch (e) {
      kPrint('Error verifying OTP: $e');
      SnackBarService.to
          .showMessage(message: 'Something went wrong please try later');
      rethrow;
    }
  }

  Future<ProfileData?> fetchUserProfile(String userId) async {
    try {
      kPrint('🥸🥸🥸🥸🥸🥸🥸🥸🥸: $userId');
      final uri = AppUrls.getProfileData;
      kPrint('Request URL: $uri');

      final requestBody = {
        'USERID': userId
      };

      final response = await apiClient.post(
        uri,
        data: requestBody,
      );

      // Step 4: DebugAppDebugPrint.log the full body
      HelperMethods.printLongString(response.body.toString());

      final responseData = response.body;

      // Step 5: Parse if success
      if (responseData['status'] == 'Success') {
        final output = responseData['output'] as List;

        if (output.isNotEmpty) {
          // Map the first object to ProfileData
          return ProfileData.fromJson(output.first);
        }
      } else {
        kPrint(
            'No profile data found: ${responseData['message']}');
      }

      return null;
    } catch (e) {
      kPrint('Error fetching profile data: $e');
      rethrow;
    }
  }

  // log out user service
  Future<bool> logOutUser(String userId) async {
    try {
      final response = await apiClient.post(
        AppUrls.logout,
        data: {
          'USERID': userId,
          'ActiveStatus': '0',
        },
      );

      kPrint('Status Code: ${response.statusCode}');
      kPrint('Response Body: ${response.body}');

      final data = response.body;

      if (data['status'] == 'Success') {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      SnackBarService.to
          .showMessage(message: 'Something went wrong please try later');
      rethrow;
    }
  }

  // check the new version
  Future<bool> checkNewVersion(String versionCode) async {
    try {
      if (kDebugMode) {
        kPrint('checking update for version : $versionCode');
      }

      final response = await apiClient.post(
        AppUrls.checkApplicationUpdate,
        data: {
          'aplicationId': '100',
          'versionname': versionCode,
        },
      );

      kPrint('Status Code: ${response.statusCode}');
      kPrint('Response Body Version Update: ${response.body}');

      final data = response.body;

      // API now always returns status: Success on a successful call
      if (data['status'] != 'Success') {
        return false;
      }

      final output = data['output'];
      if (output is! List || output.isEmpty) {
        return false;
      }

      final latestVersionStr = output[0]['Version_number']?.toString();
      if (latestVersionStr == null || latestVersionStr.isEmpty) {
        return false;
      }

      // Compare semantic versions (e.g. 1.39.0 vs 1.26.0)
      final needsUpdate = _isVersionGreater(latestVersionStr, versionCode);

      if (needsUpdate) {
        SnackBarService.to.showMessage(
          message: data['message'] ?? 'New version available',
        );
      }

      return needsUpdate;
    } catch (e) {
      kPrint('checkNewVersion error: $e');
      return false;
    }
  }

  /// Returns true if [serverVersion] > [currentVersion]
  /// Returns true if [serverVersion] > [currentVersion]
  /// Works with versions like "1.33", "1.39.0", "2.0", "1.2.3.4", etc.
  bool _isVersionGreater(String serverVersion, String currentVersion) {
    try {
      final serverParts = serverVersion
          .split('.')
          .map((e) => int.tryParse(e.trim()) ?? 0)
          .toList();
      final currentParts = currentVersion
          .split('.')
          .map((e) => int.tryParse(e.trim()) ?? 0)
          .toList();

      // Make both lists the same length by padding with zeros
      final maxLength = max(serverParts.length, currentParts.length);
      while (serverParts.length < maxLength) {
        serverParts.add(0);
      }
      while (currentParts.length < maxLength) {
        currentParts.add(0);
      }

      for (int i = 0; i < maxLength; i++) {
        if (serverParts[i] > currentParts[i]) return true;
        if (serverParts[i] < currentParts[i]) return false;
      }

      return false; // versions are equal
    } catch (e) {
      // Fallback if something unexpected happens
      return serverVersion.compareTo(currentVersion) > 0;
    }
  }
/*Future<bool> checkNewVersion(String versionCode) async {
    try {
      if (kDebugMode) {
        kPrint('checking update for version : $versionCode');
      }

      final response = await apiClient.post(
        AppUrls.checkApplicationUpdate,
        data: {
          'aplicationId': '100',
          'versionname': versionCode,
        },
      );

      kPrint('Status Code: ${response.statusCode}');
      kPrint(
          'Response Body Version Update: ${response.body}');

      final data = response.body;

      if (data['status'] == 'Success') {
        SnackBarService.to.showMessage(message: data['message']);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }*/
}
