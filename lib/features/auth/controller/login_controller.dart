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

class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final mathAnswerController = TextEditingController();
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final RxBool isReturningUser = false.obs;
  final RxString savedUsername = ''.obs;

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
    generateMathProblem();
    _prefillSavedCredentials();
  }

  @override
  void onClose() {
    // emailController.dispose();
    // passwordController.dispose();
    // mathAnswerController.dispose();
    super.onClose();
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
      mathAnswerController.text = correctAnswer.toString();
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
      mathAnswerController.clear();
    }
  }

  Future<void> signInWithDifferent() async {
    await _authManager.logoutUser(clearCredentials: true);
    isReturningUser.value = false;
    savedUsername.value = '';
    selectedBetaUser.value = null;
    emailController.clear();
    passwordController.clear();
    mathAnswerController.clear();
    generateMathProblem();
  }

  void generateMathProblem() {
    final random = Random();
    num1.value = random.nextInt(20) + 1;
    num2.value = random.nextInt(20) + 1;
    operator.value = '+';
    correctAnswer = num1.value + num2.value;
    mathAnswerController.clear();
  }

  String? validateUserName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username is required';
    }
    final regex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!regex.hasMatch(value)) {
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

  Future<void> login() async {
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      final loginResponse = await _loginService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (loginResponse.status == 'Success') {
        await _authManager.saveCredentials(
          emailController.text.trim(),
          passwordController.text.trim(),
        );
        await _authManager.saveLoginResponseModel(loginResponse);
        Get.find<SessionCoordinator>().notifyLoginSuccess();
        await _authManager.setUserRole(loginResponse.user?.designation);
        await fetchUserProfile(loginResponse.user!.empCode.toString());
        RouteManager.redirectToHomeDashboard();
      } else {
        generateMathProblem();
        SnackBarService.to.showMessage(message: loginResponse.message);
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.replaceFirst('Exception: ', '');
      }
      generateMathProblem();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUserProfile(String userId) async {
    try {
      isLoading.value = true;
      final String encodedUserId = base64.encode(utf8.encode(userId.toString()));
      AppLogger.log('Encoded USERID: $encodedUserId');

      // final profileData = await _loginService.fetchUserProfile(encodedUserId);
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
}