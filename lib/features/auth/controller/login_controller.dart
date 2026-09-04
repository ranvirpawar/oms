import 'dart:convert';
import 'dart:developer' as AppLogger;
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lifenity_connect/routes/route_manager.dart';

// login_controller.dart
import 'package:get/get.dart';


import '../../../network/session_coordinator.dart';
import '../../../services/auth_manager.dart';
import '../../../services/snackbar_service.dart';
import '../service/login_service.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:sms_autofill/sms_autofill.dart';

/// Add to pubspec.yaml:  sms_autofill: ^2.4.0
/// (see backend_otp_integration.md for the SMS template this depends on)

enum LoginStep { credentials, otp }

class LoginController extends GetxController with CodeAutoFill {
  // ------------------------------------------------------------------
  // STEP 1 — credentials
  // ------------------------------------------------------------------
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final isLoading = false.obs; // used for the "Continue" button (step 1)
  final isPasswordVisible = false.obs;
  final RxBool isReturningUser = false.obs;
  final RxString savedUsername = ''.obs;

  // ------------------------------------------------------------------
  // STEP 2 — OTP
  // ------------------------------------------------------------------
  final Rx<LoginStep> currentStep = LoginStep.credentials.obs;
  final otpController = TextEditingController();
  final RxString otpError = ''.obs;
  final RxBool isVerifyingOtp = false.obs;
  final RxBool isResendingOtp = false.obs;
  final RxInt resendSecondsLeft = 0.obs;
  final RxInt otpAttemptsLeft = 5.obs;
  final RxString maskedMobile = ''.obs;

  static const int otpLength = 4;
  static const int _resendCooldownSeconds = 30;
  static const int _maxOtpAttempts = 5;

  int? _loginUserId;
  Timer? _resendTimer;

  // ------------------------------------------------------------------
  // LEGACY — math captcha. Kept intact per product request but no
  // longer rendered or invoked anywhere in the login flow. Safe to
  // delete later; left here in case it needs to come back.
  // ------------------------------------------------------------------
  final mathAnswerController = TextEditingController();
  final RxInt num1 = 0.obs;
  final RxInt num2 = 0.obs;
  final RxString operator = '+'.obs;
  int correctAnswer = 0;

  final LoginService _loginService = Get.put(LoginService());
  final AuthManager _authManager = Get.find<AuthManager>();

  final Rx<String?> selectedBetaUser = Rx<String?>(null);
  final Map<String, Map<String, String>> betaUsers = {
    'Phlebotomist': {'user': '9975020273', 'pass': '123456'},
    'Runnerboy': {'user': '9975020297', 'pass': '123456'},
    'Team Lead': {'user': '9975020260', 'pass': '123456'},
    'Lab Accession': {'user': '9975020298', 'pass': '1234567'},
    'Connector': {'user': '8007758869', 'pass': '123456'},
    'Medical Officer': {'user': '8788789878', 'pass': '123456'},
    'BMC Admin': {'user': 'BMCadmin', 'pass': 'Admin2123'},
    'EHO': {'user': '8806191092', 'pass': '123456'},
    'CMS': {'user': '8975276087', 'pass': '123456'},
  };

  @override
  void onInit() {
    super.onInit();
    generateMathProblem(); // kept for parity; unused by the UI now
    _prefillSavedCredentials();

    if (kDebugMode) {
      // One-time helper so you can hand the hash to the backend team.
      // Prints something like: FA+9qCX9VSu
      SmsAutoFill().getAppSignature.then((sig) {
        AppLogger.log('📱 SMS Autofill app signature: $sig');
      }).catchError((_) {});
    }
  }

  @override
  void onClose() {
    _resendTimer?.cancel();
    cancel(); // stop the SMS Retriever listener (CodeAutoFill mixin)
    emailController.dispose();
    passwordController.dispose();
    mathAnswerController.dispose();
    otpController.dispose();
    super.onClose();
  }

  /// Called by the sms_autofill plugin when a matching SMS arrives.
  @override
  void codeUpdated() {
    final incoming = code?.trim() ?? '';
    if (incoming.length == otpLength) {
      otpController.text = incoming;
      verifyOtp();
    }
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void fillBetaCredentials(String? userKey) {
    selectedBetaUser.value = userKey;
    if (userKey != null && betaUsers.containsKey(userKey)) {
      // Force fresh login UI — never show welcome-back banner for beta users
      isReturningUser.value = false;
      emailController.text = betaUsers[userKey]!['user']!;
      passwordController.text = betaUsers[userKey]!['pass']!;
      formKey.currentState?.validate();
    }
  }

  Future<void> _prefillSavedCredentials() async {
    final creds = await Get.find<AuthManager>().getSavedCredentials();
    if (creds != null) {
      emailController.text = creds.username;
      passwordController.text = creds.password;
      savedUsername.value = creds.username;
      isReturningUser.value = true;
    }
  }

  Future<void> signInWithDifferent() async {
    await _authManager.logoutUser(clearCredentials: true);
    isReturningUser.value = false;
    savedUsername.value = '';
    selectedBetaUser.value = null;
    emailController.clear();
    passwordController.clear();
    _resetOtpState();
    currentStep.value = LoginStep.credentials;
  }

  // ------------------------------------------------------------------
  // Validators
  // ------------------------------------------------------------------
  String? validateUserName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    final regex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!regex.hasMatch(value.trim())) {
      return 'Username can be only alphanumeric';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // ------------------------------------------------------------------
  // STEP 1 — request OTP (was `login()`)
  // ------------------------------------------------------------------
  Future<void> requestOtp() async {
    if (!formKey.currentState!.validate()) return;
    if (isLoading.value) return;

    try {
      isLoading.value = true;

      final loginResponse = await _loginService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (loginResponse.status == 'Success') {
        // NOTE: adjust these field names to match your actual
        // LoginResponseModel once the backend team confirms the
        // /api/Legacy/Login response shape (see backend template doc).
        _loginUserId = loginResponse.userId;
        maskedMobile.value = loginResponse.mobileNo ?? '';

        _resetOtpState();
        currentStep.value = LoginStep.otp;
        _startResendCooldown();
        await _startSmsListener();
      } else {
        SnackBarService.to.showMessage(message: loginResponse.message);
      }
    } catch (e) {
      SnackBarService.to.showMessage(message: _cleanError(e));
    } finally {
      isLoading.value = false;
    }
  }

  // ------------------------------------------------------------------
  // STEP 2 — verify OTP
  // ------------------------------------------------------------------
  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();

    if (otp.length != otpLength) {
      otpError.value = 'Enter the $otpLength-digit code';
      return;
    }
    if (_loginUserId == null) {
      otpError.value = 'Your session expired. Please log in again.';
      return;
    }
    if (isVerifyingOtp.value) return;

    try {
      isVerifyingOtp.value = true;
      otpError.value = '';

      final verifyResponse = await _loginService.verifyLoginOtp(
        userId: _loginUserId!,
        otp: otp,
      );

      if (verifyResponse.status == 'Success') {
        cancel();
        _resendTimer?.cancel();

        await _authManager.saveCredentials(
          emailController.text.trim(),
          passwordController.text.trim(),
        );
        await _authManager.saveLoginResponseModel(verifyResponse);
        Get.find<SessionCoordinator>().notifyLoginSuccess();
        await _authManager.setUserRole(verifyResponse.user?.designation);
        await fetchUserProfile(verifyResponse.user!.empCode.toString());
        RouteManager.redirectToHomeDashboard();
      } else {
        otpAttemptsLeft.value = (otpAttemptsLeft.value - 1).clamp(0, _maxOtpAttempts);
        otpController.clear();

        if (otpAttemptsLeft.value == 0) {
          otpError.value = 'Too many incorrect attempts. Please request a new code.';
        } else {
          otpError.value = (verifyResponse.message.isNotEmpty)
              ? verifyResponse.message
              : 'Incorrect code. ${otpAttemptsLeft.value} attempt(s) left.';
        }
      }
    } catch (e) {
      otpController.clear();
      otpError.value = _cleanError(e);
    } finally {
      isVerifyingOtp.value = false;
    }
  }

  // ------------------------------------------------------------------
  // Resend
  // ------------------------------------------------------------------
  Future<void> resendOtp() async {
    if (resendSecondsLeft.value > 0 || isResendingOtp.value) return;

    try {
      isResendingOtp.value = true;

      final loginResponse = await _loginService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (loginResponse.status == 'Success') {
        _loginUserId = loginResponse.userId;
        _resetOtpState();
        _startResendCooldown();
        await _startSmsListener();
        SnackBarService.to.showMessage(message: 'A new code has been sent.');
      } else {
        SnackBarService.to.showMessage(message: loginResponse.message);
      }
    } catch (e) {
      SnackBarService.to.showMessage(message: _cleanError(e));
    } finally {
      isResendingOtp.value = false;
    }
  }

  void backToCredentials() {
    cancel();
    _resendTimer?.cancel();
    currentStep.value = LoginStep.credentials;
    _resetOtpState();
    _loginUserId = null;
  }

  void _resetOtpState() {
    otpController.clear();
    otpError.value = '';
    otpAttemptsLeft.value = _maxOtpAttempts;
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    resendSecondsLeft.value = _resendCooldownSeconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (resendSecondsLeft.value <= 1) {
        t.cancel();
        resendSecondsLeft.value = 0;
      } else {
        resendSecondsLeft.value--;
      }
    });
  }

  Future<void> _startSmsListener() async {
    try {
      await SmsAutoFill().unregisterListener();
       listenForCode();
    } catch (_) {
      // No Play Services (emulator/older device) — user can still type
      // the code manually, so we swallow this rather than surfacing it.
    }
  }

  String _cleanError(Object e) {
    String msg = e.toString();
    if (msg.startsWith('Exception: ')) {
      msg = msg.replaceFirst('Exception: ', '');
    }
    return msg.isEmpty ? 'Something went wrong. Please try again.' : msg;
  }

  // ------------------------------------------------------------------
  // Profile fetch (unchanged)
  // ------------------------------------------------------------------
  Future<void> fetchUserProfile(String userId) async {
    try {
      isLoading.value = true;
      // final String encodedUserId = base64.encode(utf8.encode(userId.toString()));
      // AppLogger.log('Encoded USERID: $encodedUserId');

      final profileData = await _loginService.fetchUserProfile(userId.toString());
      if (profileData != null) {
        await _authManager.saveUserProfileToStorage(profileData);
        AppLogger.log('✅ User profile saved in AuthManager');
      } else {
        AppLogger.log('⚠ No profile data found');
      }
    } catch (e) {
      AppLogger.log('❌ Error fetching user profile: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ------------------------------------------------------------------
  // LEGACY — math captcha (unused, kept per product request)
  // ------------------------------------------------------------------
  void generateMathProblem() {
    final random = Random();
    num1.value = random.nextInt(20) + 1;
    num2.value = random.nextInt(20) + 1;
    operator.value = '+';
    correctAnswer = num1.value + num2.value;
    mathAnswerController.clear();
  }

  String? validateMathAnswer(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please solve the math problem';
    }
    final userAnswer = int.tryParse(value);
    if (userAnswer == null) {
      return 'Please enter a valid number';
    }
    if (userAnswer != correctAnswer) {
      return 'Incorrect answer. Please try again';
    }
    return null;
  }
}