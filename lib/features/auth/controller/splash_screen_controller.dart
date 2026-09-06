// Controller for handling splash screen logic

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/routes/route_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../services/auth_manager.dart';
import '../service/login_service.dart';
import '../view/login_screen.dart';
import '../view/update_bottom_sheet.dart';

class SplashController extends GetxController {
  final RxBool showUpdateSheet = false.obs;
  bool _navigated = false;

  final AuthManager _authManager = Get.find<AuthManager>();
  final LoginService _loginService = Get.put(LoginService());

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSplashFlow());
  }

  Future<void> _runSplashFlow() async {
    // Step 1: Android-only API version check
    final needsUpdate = await _checkForUpdate();
    if (needsUpdate) {
      return; // Block navigation — user must update
    }


    // Step 2: Proceed to auth routing
    await _navigateAfterSplash();
  }

  Future<bool> _checkForUpdate() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final version = packageInfo.version;

      final needsUpdate = await _loginService.checkNewVersion(version);

      if (needsUpdate) {
        // Show the sheet after frame is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          UpdateBottomSheet.show(
            currentVersion: packageInfo.version,
          );
        });
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _navigateAfterSplash() async {
    if (_navigated) return;
    _navigated = true;

    try {
      await _authManager.saveDeviceInfo();

      // Feature 2: Daily session expiry check
      final expired = await _authManager.isSessionExpired();
      if (expired) {
        if (kDebugMode) print('Session expired — logging out');
        await _authManager.logoutUser(clearCredentials: false); // ← preserve creds
        return;
      }

      await Future.delayed(const Duration(seconds: 2));

      final isLoggedIn = await _authManager.isUserLoggedIn();

      if (kDebugMode) print('User logged in: $isLoggedIn');

      if (isLoggedIn) {
        RouteManager.redirectToHomeDashboard();
      } else {
        Get.offAll(() => const LoginScreenView());
      }
    } catch (e) {
      if (kDebugMode) print('Navigation error: $e');
      Get.offAll(() => const LoginScreenView());
    }
  }
}


