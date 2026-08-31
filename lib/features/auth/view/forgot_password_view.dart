import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../constants/app_assets.dart';
import '../../../theme/app_colors.dart';
import '../controller/forgot_password_controller.dart';



class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final ForgotPasswordController controller =
        Get.put(ForgotPasswordController());

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Logo zone ──────────────────────────────────────────────────────
          const SizedBox(height: 40),
          Flexible(
            flex: 2,
            child: Stack(
              children: [
                Center(
                  child: Image.asset(
                    AppAssets.lifenityLogo,
                    fit: BoxFit.contain,
                    width: MediaQuery.of(context).size.width * 0.6,
                  ),
                ),
                // Back button — top-left
                Positioned(
                  top: 0,
                  left: 16,
                  child: SafeArea(
                    child: GestureDetector(
                      onTap: () => Get.back(),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Primary card zone ──────────────────────────────────────────────
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(40),
                  topLeft: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Obx(
                  () => controller.isOtpSent.value
                      ? _ResetPhase(controller: controller)
                      : _MobilePhase(controller: controller),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phase 1 — Mobile number input
// ─────────────────────────────────────────────────────────────────────────────

class _MobilePhase extends StatelessWidget {
  const _MobilePhase({required this.controller});
  final ForgotPasswordController controller;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.mobileFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),

            // Icon badge
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Forgot Password?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 6),

            Text(
              'Enter your registered mobile number\nand we\'ll send you an OTP.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.75),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 28),

            // Mobile number field
            _FpTextField(
              controller: controller.mobileController,
              hintText: 'Mobile Number',
              icon: Icons.phone_android_rounded,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              validator: controller.validateMobile,
            ),

            const SizedBox(height: 32),

            // Send OTP button
            Obx(() => _PrimaryButton(
                  label: 'SEND OTP',
                  isLoading: controller.isLoading.value,
                  onTap: controller.sendOtp,
                )),

            const SizedBox(height: 20),

            // Back to login
            GestureDetector(
              onTap: () => Get.back(),
              child: RichText(
                text: TextSpan(
                  text: 'Remember your password? ',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Phase 2 — OTP + new password + confirm
// ─────────────────────────────────────────────────────────────────────────────

class _ResetPhase extends StatelessWidget {
  const _ResetPhase({required this.controller});
  final ForgotPasswordController controller;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.resetFormKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 8),

            // Icon badge
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              'Verify & Reset',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 6),

            // Shows which number OTP was sent to
            // ✅ After
            Text(
              'OTP sent to +91 ${controller.mobileController.text}',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.75),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 28),

            // OTP field
            _FpTextField(
              controller: controller.otpController,
              hintText: 'Enter OTP',
              icon: Icons.pin_rounded,
              keyboardType: TextInputType.number,
             /* inputFormatters: [
               *//* FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),*//*
              ],*/
              validator: controller.validateOtp,
            ),

            const SizedBox(height: 16),

            // New password field
            Obx(() => _FpTextField(
                  controller: controller.newPasswordController,
                  hintText: 'New Password',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  isPasswordVisible: controller.isNewPasswordVisible.value,
                  onTogglePassword: controller.toggleNewPasswordVisibility,
                  validator: controller.validateNewPassword,
                )),

            const SizedBox(height: 16),

            // Confirm password field
            Obx(() => _FpTextField(
                  controller: controller.confirmPasswordController,
                  hintText: 'Confirm Password',
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                  isPasswordVisible:
                      controller.isConfirmPasswordVisible.value,
                  onTogglePassword:
                      controller.toggleConfirmPasswordVisibility,
                  validator: controller.validateConfirmPassword,
                )),

            const SizedBox(height: 32),

            // Reset Password button
            Obx(() => _PrimaryButton(
                  label: 'RESET PASSWORD',
                  isLoading: controller.isLoading.value,
                  onTap: controller.resetPassword,
                )),

            const SizedBox(height: 16),

            // Resend OTP / change number
            GestureDetector(
              onTap: controller.goBackToMobilePhase,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    color: Colors.white.withOpacity(0.8),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Resend OTP / Change number',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable: styled text form field matching login screen aesthetic
// ─────────────────────────────────────────────────────────────────────────────

class _FpTextField extends StatelessWidget {
  const _FpTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.onTogglePassword,
  });

  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final bool isPassword;
  final bool isPasswordVisible;
  final VoidCallback? onTogglePassword;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: isPassword && !isPasswordVisible,
      inputFormatters: inputFormatters,
      validator: validator,
      cursorColor: Colors.white,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.8), size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white.withOpacity(0.7),
                  size: 20,
                ),
                onPressed: onTogglePassword,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        errorStyle: const TextStyle(color: Colors.white70, fontSize: 12),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable: white elevated button — matches login screen login button exactly
// ─────────────────────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
      ),
    );
  }
}
