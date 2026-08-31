import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/componenents/info_row_widget.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_recollection/controller/recollection_tests_controller.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_recollection/model/rejected_tests_model.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_recollection/view/widget/accept_recollection_sheet.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';

import '../../../../constants/app_assets.dart';
import '../../../../constants/app_strings.dart';
import '../../../../theme/app_colors.dart';
import 'widget/deny_recollection_sheet.dart';

class RecollectionTestSelectionView extends StatelessWidget {
  RecollectionTestSelectionView({super.key});

  final RecollectTestsController controller =
      Get.put(RecollectTestsController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
        appBar: CustomAppBar(
          title: 'Recollect Sample',
          actions: [
            Obx(() => controller.selectedTests.isNotEmpty
                ? TextButton(
                    onPressed: () => controller.clearAllSelections(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textPrimaryDark,
                    ),
                    child: const Text(
                      AppStrings.clearAll,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                : const SizedBox()),
            const SizedBox(width: 8),
          ],
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.rejectedTestsList.isEmpty) {
            return const Center(child: Text('No rejected tests found.'));
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // patient details card
                patientDetailsCard(
                    controller.rejectedTestsList.first, [], theme),

                // select tests
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              SvgPicture.asset(
                                AppAssets.testTube,
                                width: 16,
                                height: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "Select ${controller.rejectedTestsList.length > 1 ? 'Tests' : 'Test'}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () {
                                  controller.selectAllTests();
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline,
                                      size: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'All',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Obx(() => Text(
                                    '${controller.selectedTests.length}/${controller.rejectedTestsList.length}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: theme.colorScheme.primary,
                                    ),
                                  )),
                            ],
                          ),
                        ),
                        // Test List
                        Expanded(
                          child: controller.rejectedTestsList.isEmpty
                              ? const Center(
                                  child: Text('No rejected tests available.'),
                                )
                              : ListView.builder(
                                  itemCount:
                                      controller.rejectedTestsList.length,
                                  itemBuilder: (context, index) {
                                    final test =
                                        controller.rejectedTestsList[index];
                                    return _buildCompactTestTile(test, context);
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Recollect Button
                Obx(() => controller.selectedTests.isNotEmpty
                    ? Row(
                        children: [
                          Expanded(child: _buildDenyRecollectionButton()),
                          const SizedBox(width: 10),
                          Expanded(child: _buildRecollectButton()),
                        ],
                      )
                    : const SizedBox())
              ],
            ),
          );
        }));
  }

  Widget patientDetailsCard(
      RejectedTests patient, List<String> rejectedTests, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                Colors.grey.shade50,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Patient Name - Compact Header
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          SvgPicture.asset(
                            AppAssets.patient,
                            width: 18,
                            height: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              patient.fullName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Age and Gender
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${patient.age} ${patient.ageTitle.toLowerCase()}, ${patient.gender}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Divider(height: 1),
                const SizedBox(height: 6),
                // Order ID and visit date
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: InfoRow(
                      icon: AppAssets.barcodeIcon,
                      title: AppStrings.barcode,
                      value: patient.orderId.toString(),
                      iconSize: 16,
                    )),
                    const SizedBox(width: 10),
                    Expanded(
                        child: InfoRow(
                      icon: AppAssets.calendarIcon,
                      title: 'Visit Date',
                      value: patient.visitDate.split(' ').first,
                      iconSize: 16,
                    )),
                  ],
                ),
                const SizedBox(height: 6),
                // lab and facility
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: InfoRow(
                        icon: AppAssets.facility,
                        title: AppStrings.labName,
                        value: patient.labName,
                        iconSize: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InfoRow(
                        icon: AppAssets.facility,
                        title: AppStrings.facilityName,
                        value: patient.facilityName,
                        iconSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // rejected date and reason
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: InfoRow(
                      icon: AppAssets.fileNoteIcon,
                      title: 'Rejected Date',
                      value: patient.rejectionDate.split(' ').first,
                      iconSize: 16,
                    )),
                    const SizedBox(width: 10),
                    Expanded(
                        child: InfoRow(
                      icon: AppAssets.fileNoteIcon,
                      title: 'Rejection Reason',
                      value: patient.reason,
                      iconSize: 16,
                    )),
                  ],
                ),
                const SizedBox(height: 6),
                // number of rejected count and mobile
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: InfoRow(
                      icon: AppAssets.fileNoteIcon,
                      title: 'Rejected count',
                      value: controller.rejectedTestsList.length.toString(),
                      iconSize: 16,
                    )),
                    const SizedBox(width: 10),
                    Expanded(
                        child: GestureDetector(
                      onTap: () => controller.makeCall(patient.mobile),
                      child: InfoRow(
                        icon: AppAssets.mobileIcon,
                        title: AppStrings.mobileNumber,
                        value: patient.mobile,
                        iconSize: 16,
                        valueColor: theme.colorScheme.primary,
                      ),
                    )),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactTestTile(RejectedTests test, BuildContext context) {
    return Obx(() {
      final isSelected = controller.isTestSelected(test);

      return InkWell(
        onTap: () => controller.toggleTestSelection(test),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.05)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              // Custom checkbox
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey[400]!,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 14,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              // Test name
              Expanded(
                child: Text(
                  test.serviceName ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildRecollectButton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () { Get.bottomSheet(

            AcceptRecollectionBottomSheet(controller: controller),
            isScrollControlled: true,


        );},
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 36),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Recollect ${controller.selectedTests.length} test${controller.selectedTests.length > 1 ? 's' : ''}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDenyRecollectionButton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 8),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          if (controller.selectedTests.isEmpty) {
            // Show snackbar in main view's context (safe here)
            // Assuming SnackBarService uses Get.snackbar or main Scaffold
            Get.snackbar('Error', 'Please select at least one test to deny.');
            return;
          }
          if (controller.denyRemarkList.isEmpty) {
            Get.snackbar('Error', 'No deny remarks available.');
            return;
          }
          Get.bottomSheet(DenyRemarkBottomSheet(controller: controller));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.secondary,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 36),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.secondary, width: 1),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Deny Recollection',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
