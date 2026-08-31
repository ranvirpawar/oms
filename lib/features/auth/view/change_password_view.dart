import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../../../utils/widgets/custom_appbar.dart';
import '../controller/change_password_controller.dart';


class ChangePasswordView extends StatelessWidget {
  const ChangePasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final ChangePasswordController controller =
        Get.put(ChangePasswordController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: const CustomAppBar(title: 'Change Password'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Info banner ────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your new password must be at least 6 characters and different from your current password.',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.primary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Password fields card ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Old password
                    Obx(() => _PasswordField(
                          controller: controller.oldPasswordController,
                          label: 'Current Password',
                          hint: 'Enter your current password',
                          isVisible: controller.isOldPasswordVisible.value,
                          onToggle: controller.toggleOldPasswordVisibility,
                          validator: controller.validateOldPassword,
                        )),

                    const _FieldDivider(),

                    // New password
                    Obx(() => _PasswordField(
                          controller: controller.newPasswordController,
                          label: 'New Password',
                          hint: 'Enter your new password',
                          isVisible: controller.isNewPasswordVisible.value,
                          onToggle: controller.toggleNewPasswordVisibility,
                          validator: controller.validateNewPassword,
                        )),

                    const _FieldDivider(),

                    // Confirm password
                    Obx(() => _PasswordField(
                          controller: controller.confirmPasswordController,
                          label: 'Confirm New Password',
                          hint: 'Re-enter your new password',
                          isVisible: controller.isConfirmPasswordVisible.value,
                          onToggle: controller.toggleConfirmPasswordVisibility,
                          validator: controller.validateConfirmPassword,
                        )),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Submit button ──────────────────────────────────────────────
              Obx(() => SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.changePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        disabledBackgroundColor:
                            AppColors.primary.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: controller.isLoading.value
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'UPDATE PASSWORD',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2.5,
                              ),
                            ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable: labelled password field styled for the white card
// ─────────────────────────────────────────────────────────────────────────────

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.isVisible,
    required this.onToggle,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool isVisible;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: !isVisible,
          validator: validator,
          cursorColor: AppColors.primary,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9@#$!%^&*]')),
          ],
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: AppColors.primary.withOpacity(0.7),
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.grey.shade400,
                size: 20,
              ),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: const Color(0xFFF5F7FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Colors.redAccent, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Thin divider between fields inside the card
// ─────────────────────────────────────────────────────────────────────────────

class _FieldDivider extends StatelessWidget {
  const _FieldDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Divider(color: Colors.grey.shade100, thickness: 1),
    );
  }
}
