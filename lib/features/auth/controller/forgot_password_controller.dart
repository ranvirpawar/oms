import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../service/forgot_password_service.dart';
import '../../../utils/ui_designs/liquid_snackbar.dart';


class ForgotPasswordController extends GetxController {
  // Phase 1 — Mobile Number
  final mobileFormKey = GlobalKey<FormState>();
  final mobileController = TextEditingController();

  // Phase 2 — OTP + New Password
  final resetFormKey = GlobalKey<FormState>();
  final otpController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // State
  final RxBool isLoading = false.obs;
  final RxBool isOtpSent = false.obs;
  final RxBool isNewPasswordVisible = false.obs;
  final RxBool isConfirmPasswordVisible = false.obs;

  final ForgotPasswordService _forgotPasswordService =
      Get.put(ForgotPasswordService());

  @override
  void onClose() {
    mobileController.dispose();
    otpController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  // ─── Validators ──────────────────────────────────────────────────────────

  String? validateMobile(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mobile number is required';
    }
    if (!RegExp(r'^\d{10}$').hasMatch(value.trim())) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  String? validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'OTP is required';
    }
    if (value.trim().length < 4) {
      return 'Enter a valid OTP';
    }
    return null;
  }

  String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // ─── Phase 1: Send OTP ───────────────────────────────────────────────────

  Future<void> sendOtp() async {
    if (!mobileFormKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      final success = await _forgotPasswordService.sendOtp(
        mobileController.text.trim(),
      );

      if (success) {
        isOtpSent.value = true;
        _showSnack(
          title: 'OTP Sent',
          message: 'OTP sent successfully',
          isError: false,
        );
      }
    } catch (_) {
      // Error already shown by service
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Phase 2: Reset Password ─────────────────────────────────────────────

  Future<void> resetPassword() async {
    if (!resetFormKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      final success = await _forgotPasswordService.resetPassword(
        mobileNo: mobileController.text.trim(),
        otp: otpController.text.trim(),
        newPassword: newPasswordController.text.trim(),
      );

      if (success) {

        Get.back();
        _showSnack(
          title: 'Success',
          message: 'Password reset successfully',
          isError: false,
        );

      }
    } catch (_) {
      // Error already shown by service
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  void toggleNewPasswordVisibility() {
    isNewPasswordVisible.value = !isNewPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  /// Go back to Phase 1 (change number / resend OTP)
  void goBackToMobilePhase() {
    isOtpSent.value = false;
    otpController.clear();
    newPasswordController.clear();
    confirmPasswordController.clear();
  }

  void _showSnack({
    required String title,
    required String message,
    required bool isError,
  }) {
    if (isError) {
      LiquidSnack.error(message, title: title);
    } else {
      LiquidSnack.success(message, title: title);
    }
  }
}
