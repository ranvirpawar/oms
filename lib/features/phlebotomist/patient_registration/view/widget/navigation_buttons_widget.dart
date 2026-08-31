import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../constants/app_strings.dart';
import '../../../../../services/snackbar_service.dart';
import '../../../../../theme/app_colors.dart';
import '../../controller/patient_registration_controller.dart';

class NavigationButtons extends StatelessWidget {
  final PatientRegistrationController controller;

  const NavigationButtons({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return _buildNavigationButtons(context);
  }

  Widget _buildNavigationButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        final double screenWidth = MediaQuery.of(context).size.width;
        final double spacing = screenWidth > 600 ? 12.0 : 8.0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Previous Button
            if (controller.selectedSection.value > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    controller
                        .selectSection(controller.selectedSection.value - 1);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.tertiary900,
                    side: const BorderSide(
                      color: AppColors.tertiary900,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    minimumSize: const Size(0, 40),
                    textStyle: const TextStyle(fontSize: 14),
                  ),
                  child: const Text(AppStrings.previous),
                ),
              ),

            if (controller.selectedSection.value > 0) SizedBox(width: spacing),

            // Reset Button
            Expanded(
              /*fit: FlexFit.tight,*/
              flex: 1,
              child: OutlinedButton(
                onPressed: () {
                  Get.dialog(
                    AlertDialog(
                      title: const Text(AppStrings.resetFormTitle),
                      content: const Text(AppStrings.resetFormMessage),
                      actions: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Get.back();
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 8),
                                ),
                                child: const Text(AppStrings.cancel),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Get.back();
                                  controller.resetForm();
                                  SnackBarService.to.showMessage(
                                    message: AppStrings.formResetSuccess,
                                  );
                                },
                                child: const Text(AppStrings.reset),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.tertiary900,
                  side: const BorderSide(
                    color: AppColors.tertiary900,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), 
                  minimumSize: const Size(0, 40),
                  textStyle: const TextStyle(fontSize: 14),
                ),
                child: const Text(AppStrings.reset),
              ),
            ),
            SizedBox(width: spacing),
            // Next / Add Tests Button
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  debugPrint('👉 Button pressed');
                  bool isValid = false;
                  final int section = controller.selectedSection.value;
                  debugPrint('📍 Current section: $section');
                  switch (section) {
                    case 0:
                      isValid = controller.validateLabInfo();
                      debugPrint('🧪 Lab Info validation: $isValid');
                      break;
                    case 1:
                      isValid = controller.validatePatientInfo();
                      debugPrint('🧍 Patient Info validation: $isValid');
                      break;
                    case 2:
                      isValid = controller.validateResidenceInfo();
                      debugPrint('🏠 Residence Info validation: $isValid');
                      break;
                    default:
                      debugPrint('❌ Invalid section index: $section');
                      return;
                  }

                  if (!isValid) {
                    debugPrint('❌ Validation failed. Navigation aborted.');
                    return;
                  }

                  if (section == 2) {
                    debugPrint(
                        '✅ Navigating to TestSelectionView with all form data');

                    controller.submitForm();
                  } else {
                    controller.selectSection(section + 1);
                    debugPrint('➡️ Navigating to next section: ${section + 1}');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: controller.selectedSection.value == 2
                      ? AppColors.primary900
                      : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12), // smaller
                  minimumSize: const Size(0, 40), // set a fixed compact height
                  textStyle: const TextStyle(fontSize: 14),
                ),
                child: Text(
                  controller.selectedSection.value == 2 ? 'Add Tests' : 'Next',
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/*Widget _buildNavigationButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        final double screenWidth = MediaQuery.of(context).size.width;
        final double spacing = screenWidth > 600 ? 12.0 : 8.0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Previous Button
            if (controller.selectedSection.value > 0)
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    controller
                        .selectSection(controller.selectedSection.value - 1);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tertiary900,

                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(AppStrings.previous),
                ),
              ),

            if (controller.selectedSection.value > 0) SizedBox(width: spacing),

            // Reset Button
            Expanded(
              /*fit: FlexFit.tight,*/
              flex: 1,
              child: OutlinedButton(
                onPressed: () {
                  Get.dialog(
                    AlertDialog(
                      title: const Text(AppStrings.resetFormTitle),
                      content: const Text(
                          AppStrings.resetFormMessage),
                      actions: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  Get.back();
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: BorderSide(
                                    color: AppColors.primary,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16, horizontal: 8),
                                ),
                                child: Text(AppStrings.cancel),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Get.back();
                                  controller.resetForm();
                                  SnackBarService.to.showMessage(
                                    message: AppStrings.formResetSuccess,
                                  );
                                },
                                child:  const Text(AppStrings.reset),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.tertiary900,
                  side: BorderSide(
                    color: AppColors.tertiary900,
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                ),
                child: const Text('Reset'),
              ),
            ),
            SizedBox(width: spacing),
            // Next / Add Tests Button
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  debugPrint('👉 Button pressed');

                  bool isValid = false;
                  int section = controller.selectedSection.value;
                  debugPrint('📍 Current section: $section');

                  switch (section) {
                    case 0:
                      isValid = controller.validateLabInfo();
                      debugPrint('🧪 Lab Info validation: $isValid');
                      break;
                    case 1:
                      isValid = controller.validatePatientInfo();
                      debugPrint('🧍 Patient Info validation: $isValid');
                      break;
                    case 2:
                      isValid = controller.validateResidenceInfo();
                      debugPrint('🏠 Residence Info validation: $isValid');
                      break;
                    default:
                      debugPrint('❌ Invalid section index: $section');
                      return;
                  }

                  if (!isValid) {
                    debugPrint('❌ Validation failed. Navigation aborted.');
                    return;
                  }

                  if (section == 2) {
                    debugPrint(
                        '✅ Navigating to TestSelectionView with all form data');

                    controller.submitForm();
                  } else {
                    controller.selectSection(section + 1);
                    debugPrint('➡️ Navigating to next section: ${section + 1}');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: controller.selectedSection.value == 2
                      ? AppColors.primary900
                      : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  controller.selectedSection.value == 2 ? 'Add Tests' : 'Next',
                ),
              ),
            ),
          ],
        );
      }),
    );
  }*/
