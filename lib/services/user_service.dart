import 'package:flutter/foundation.dart';

import '../features/auth/model/login_response_model.dart';
import '../features/auth/model/profile_model.dart';
import 'auth_manager.dart';
import 'package:get/get.dart';

class UserService {
  final AuthManager authManager = Get.put(AuthManager());

  Future<UserModel?> getUser() async {
    try {
      final data = await authManager.getUserData();

      if (data != null && data['user'] is Map<String, dynamic>) {
        if (kDebugMode) {
          print(data.toString());
        }
        return UserModel.fromJson(data['user']);
      } else {
        debugPrint('❌ "user" data not found or invalid');
      }
    } catch (err) {
      debugPrint('❌ Error loading user data: $err');
    }
    return null;
  }

  Future<ProfileData?> getUserProfile() async {
    try {
      final profile = await authManager.getUserProfileFromStorage();
      if (profile != null) {
        return profile;
      } else {
        debugPrint('❌ User profile not found in storage');
      }
    } catch (err) {
      debugPrint('❌ Error loading user profile: $err');
    }
    return null;
  }

  // get designation id from api


}
