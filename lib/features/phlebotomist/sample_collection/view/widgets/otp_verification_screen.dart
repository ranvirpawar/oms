// otp_verification_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';

import '../../../../../theme/app_colors.dart';
import '../../controller/sample_collection_controller.dart';
import '../sample_collection_screen.dart';

class OtpVerificationScreen extends GetView<SampleCollectionController> {
  const OtpVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Move to the collection screen once OTP is verified.
    ever<SampleCollectionStep>(controller.step, (step) {
      if (step == SampleCollectionStep.collection) {
        Get.off(() => const SampleCollectionScreen());
      }
    });

    return Scaffold(
      backgroundColor: AppColors.grayLight,
      appBar:const CustomAppBar(title: 'Verify Otp'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.sms_outlined, size: 48, color: AppColors.blue),
            const SizedBox(height: 16),
            const Text(
              'Enter the 4-digit OTP',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'OTP sent to the patient\'s registered number to confirm sample collection.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.textTertiary),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) => _OtpBox(index: index, controller: controller)),
            ),
            const SizedBox(height: 12),
            Obx(() {
              if (controller.otpError.value.isEmpty) return const SizedBox.shrink();
              return Text(
                controller.otpError.value,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: AppColors.redText, fontWeight: FontWeight.w600),
              );
            }),
            const SizedBox(height: 16),
            Obx(() {
              final seconds = controller.resendSecondsLeft.value;
              return Center(
                child: TextButton(
                  onPressed: seconds > 0 ? null : controller.resendOtp,
                  child: Text(
                    seconds > 0 ? 'Resend OTP in ${seconds}s' : 'Resend OTP',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: seconds > 0 ? AppColors.textMuted : AppColors.blue,
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            Obx(() => SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent700,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                      elevation: 0,
                    ),
                    onPressed: controller.isVerifyingOtp.value ? null : controller.verifyOtp,
                    child: controller.isVerifyingOtp.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Verify OTP',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final int index;
  final SampleCollectionController controller;
  const _OtpBox({required this.index, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1.4),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller.otpControllers[index],
        focusNode: controller.otpFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(counterText: '', border: InputBorder.none),
        onChanged: (value) => controller.onOtpDigitChanged(index, value),
      ),
    );
  }
}
