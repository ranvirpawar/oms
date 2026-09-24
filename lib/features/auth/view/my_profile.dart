import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/componenents/c_textformfeild.dart';
import 'package:lifenity_connect/componenents/otp_boxes_input.dart';
import 'package:lifenity_connect/theme/app_colors.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';
import '../controller/profile_controller.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(title: 'My Profile'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Avatar & Name/Designation
              _buildProfileHeader(),
              const SizedBox(height: 24),

              // Name Field — display-only, auto-composed from First+Middle+Last
              CFormTextField(
                controller: controller.nameController,
                label: 'Name',
                labelAbove: true,
                isRequired: false,
                isReadOnly: true,
                backgroundColor: const Color(0xFFF9FAFB),
                labelPrefix: const Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 18),

              // First Name / Middle Name / Last Name row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CFormTextField(
                      controller: controller.firstNameController,
                      label: 'First Name',
                      labelAbove: true,
                      isRequired: false,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CFormTextField(
                      controller: controller.middleNameController,
                      label: 'Middle Name',
                      labelAbove: true,
                      isRequired: false,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CFormTextField(
                      controller: controller.lastNameController,
                      label: 'Last Name',
                      labelAbove: true,
                      isRequired: false,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Mobile Number Field — locked after OTP verification
              Obx(() {
                final verified = controller.showVerifiedBadge.value;
                return CFormTextField(
                  controller: controller.mobileNumberController,
                  label: 'Mobile no.',
                  labelAbove: true,
                  isRequired: false,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  isReadOnly: verified,
                  backgroundColor: verified
                      ? const Color(0xFFF9FAFB)
                      : Colors.white,
                );
              }),
              const SizedBox(height: 8),

              // OTP section — visible only when a new 10-digit number is entered
              Obx(() => _buildOtpSection(context)),

              // ✓ Verified badge — fades in after OTP success
              Obx(() {
                if (!controller.showVerifiedBadge.value) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF16A34A),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF15803D),
                              ),
                              children: [
                                const TextSpan(text: 'New number '),
                                TextSpan(
                                  text: controller.mobileNumberController.text
                                      .trim(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const TextSpan(text: ' is verified \u2713'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 10),

              // Designation Field (Read-only with Lock icon)
              CFormTextField(
                controller: controller.designationController.text.isNotEmpty
                    ? controller.designationController
                    : controller.roleController,
                label: 'Designation',
                labelAbove: true,
                isRequired: false,
                isReadOnly: true,
                labelPrefix: const Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: Color(0xFF374151),
                ),
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 18),

              // District Field (Read-only with Lock icon)
              CFormTextField(
                controller: controller.districtController,
                label: 'District',
                labelAbove: true,
                isRequired: false,
                isReadOnly: true,
                labelPrefix: const Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: Color(0xFF374151),
                ),
                backgroundColor: Colors.white,
              ),
              const SizedBox(height: 32),

              // Cancel & Save Buttons
              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF111827),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        // Disabled when mobile changed but not yet verified,
                        // or while an OTP call is in flight.
                        onPressed:
                            controller.isMobileVerified.value &&
                                !controller.isOtpLoading.value
                            ? () => controller.saveProfile()
                            : null,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.primary.withValues(
                            alpha: 0.45,
                          ),
                          disabledForegroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── OTP section ─────────────────────────────────────────────────────────────

  Widget _buildOtpSection(BuildContext context) {
    // Nothing to show when number unchanged (already verified).
    if (!controller.showOtpSection.value && controller.isMobileVerified.value) {
      return const SizedBox.shrink();
    }

    // Show a "sending…" indicator while the send-OTP call is in flight but
    // the OTP boxes haven't appeared yet.
    if (controller.isOtpLoading.value && !controller.showOtpSection.value) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (!controller.showOtpSection.value) return const SizedBox.shrink();

    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Verify Mobile Number',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const Spacer(),
                // Resend OTP
                if (!controller.isOtpLoading.value)
                  GestureDetector(
                    onTap: () => controller.sendOtp(),
                    child: const Text(
                      'Resend OTP',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Enter the 4-digit OTP sent to ${controller.mobileNumberController.text.trim()}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),

            // OTP Boxes
            Center(
              child: OtpBoxesInput(
                key: controller.otpInputKey,
                length: 4,
                autofocus: true,
                enableAutofill: true,
                onChanged: (_) => controller.otpError.value = '',
                onCompleted: (otp) => controller.verifyOtp(otp),
                boxColor: Colors.white,
                filledBoxColor: Colors.white,
                borderColor: const Color(0xFFD1D5DB),
                filledBorderColor: AppColors.primary,
                focusBorderColor: AppColors.primary,
              ),
            ),

            // Error text
            if (controller.otpError.value.isNotEmpty) ...[
              const SizedBox(height: 10),
              Center(
                child: Text(
                  controller.otpError.value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ],

            // Loading indicator while verifying
            if (controller.isOtpLoading.value) ...[
              const SizedBox(height: 12),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  // ── Profile Header ───────────────────────────────────────────────────────────

  Widget _buildProfileHeader() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller.nameController,
      builder: (context, nameVal, _) {
        final name = nameVal.text.trim();
        final initials = _getInitials(name);
        final displayName = name.isNotEmpty ? name : 'User';
        final designation = controller.designationController.text.isNotEmpty
            ? controller.designationController.text
            : (controller.roleController.text.isNotEmpty
                  ? controller.roleController.text
                  : 'Phlebotomist');

        return Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.primary50,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    designation,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF6B7280),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'U';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}
