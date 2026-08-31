import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/features/team_lead/sample_remark/controller/sample_remark_controller.dart';
import 'package:lifenity_connect/features/team_lead/visit_details/view/widgets/custom_dropdown.dart';
import 'package:lifenity_connect/utils/animated_shimmer/sample_remark_shimmer.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';

import '../../../../constants/app_assets.dart';
import '../../../../constants/app_strings.dart';
import '../../../../theme/app_colors.dart';

import 'package:flutter_svg/flutter_svg.dart';

import '../../../../utils/helper_functions/debug_print.dart';


class SampleRemarkView extends StatelessWidget {
  SampleRemarkView({super.key});

  final SampleRemarkController controller = Get.put(SampleRemarkController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: AppStrings.sampleRemark),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: SampleRemarkShimmer());
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              // Selected Date Card
              _buildSelectedDateCard(),

              const SizedBox(height: 16),

              // Facility Name Dropdown
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomDropdown(
                      showSrNo: true,
                      label: AppStrings.facilityName,
                      items: controller.facilityNames
                          .map((e) => e.facilityName)
                          .toList(),
                      value:
                          controller.selectedFacilityName.value?.facilityName ??
                              '',
                      onChanged: (value) {
                        if (value != null && value.isNotEmpty) {
                          final selectedFacility =
                              controller.facilityNames.firstWhere(
                            (facility) => facility.facilityName == value,
                          );
                          controller.selectedFacilityName.value =
                              selectedFacility;
                          controller.fetchDataForSampleRemark();
                          CustomDebugFunction.log(
                            'Selected Facility: ${selectedFacility.facilityName}, code: ${selectedFacility.facilityId}',
                          );
                        }
                      },
                      iconPath: AppAssets.facility,
                      isRequired: true,
                    ),
                    /*ModernDropdown(

                      label: AppStrings.facilityName,
                      value: controller.selectedFacilityName.value?.facilityName ?? '',
                      items: controller.facilityNames
                          .map((e) => e.facilityName)
                          .toList(),
                      onChanged: (value) {
                        if (value != null && value.isNotEmpty) {
                          final selectedFacility = controller.facilityNames.firstWhere(
                                (facility) => facility.facilityName == value,
                          );
                          controller.selectedFacilityName.value = selectedFacility;
                          controller.fetchDataForSampleRemark();
                          CustomDebugFunction.log(
                            'Selected Facility: ${selectedFacility.facilityName}, code: ${selectedFacility.facilityId}',
                          );
                        }
                      },
                      iconPath: AppAssets.facility,
                      isRequired: true,
                      enableSearch: true,
                                       ),*/
                    if (controller.facilityInfoError.value.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                        child: Text(
                          controller.facilityInfoError.value,
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Reason Dropdown (only show when count is zero)
              if (controller.showReasonDropdown.value)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomDropdown(
                        label: 'Reason for Zero Count',
                        items: controller.remarks.map((e) => e.remark).toList(),
                        value: controller.selectedSampleRemark.value.isNotEmpty
                            ? controller.selectedSampleRemark.value
                            : 'null',
                        onChanged: (value) {
                          if (value != null && value.isNotEmpty) {
                            final selectedRemark =
                                controller.remarks.firstWhere(
                              (remark) => remark.remark == value,
                            );
                            controller.updateRemarkSelection(
                              selectedRemark.remark,
                              selectedRemark.remarkId,
                            );
                            // print selected remark
                            CustomDebugFunction.log(
                              'Selected Remark: ${selectedRemark.remark}, ID: ${selectedRemark.remarkId}',
                            );
                          }
                        },
                        iconPath: AppAssets.facility,
                        isRequired: true,
                      ),

                      /*ModernDropdown(
                        label: "Reason for Zero Count",
                        value: controller.selectedSampleRemark.value.isNotEmpty
                            ? controller.selectedSampleRemark.value
                            : "null",
                        items: controller.remarks.map((e) => e.remark).toList(),
                        onChanged: (value) {
                          if (value != null && value.isNotEmpty) {
                            final selectedRemark = controller.remarks.firstWhere(
                                  (remark) => remark.remark == value,
                            );
                            controller.updateRemarkSelection(
                              selectedRemark.remark,
                              selectedRemark.remarkId,
                            );
                          }
                        },
                        enableSearch: true,
                        iconPath: AppAssets.facility,
                        isRequired: true,
                      ),*/
                      if (controller.selectedSampleRemark.value.isEmpty &&
                          controller.showSubmitButton.value)
                        const Padding(
                          padding: EdgeInsets.only(top: 4.0, left: 8.0),
                          child: Text(
                            'Please select a reason',
                            style: TextStyle(
                                color: Colors.red, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              _buildSampleCountCard(),
              const SizedBox(height: 16),
              // Submit Button (only show when reason is selected)
            ],
          ),
        );
      }),
      bottomNavigationBar: Obx(() {
        if (!controller.showSubmitButton.value) {
          return const SizedBox();
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: controller.isSubmitting.value
                  ? null
                  : () => controller.submitZeroRemark(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: controller.isSubmitting.value
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Submit Remark',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSelectedDateCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous Day Icon
              GestureDetector(
                onTap: () {
                  final previousDay = controller.selectedDate.value!
                      .subtract(const Duration(days: 1));
                  if (previousDay.isAfter(DateTime(2020))) {
                    controller.selectDate(previousDay);
                  }
                },
                child: SvgPicture.asset(
                  AppAssets.backwardIcon,
                  height: 18,
                  width: 18,
                  color: AppColors.primary,
                ),
              ),

              // Calendar Icon and Date Display
              Flexible(
                child: GestureDetector(
                  onTap: () => _selectDate(Get.context!),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        AppAssets.calendarIcon,
                        width: 20,
                        height: 20,
                        colorFilter: const ColorFilter.mode(
                          AppColors.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Obx(() {
                        final dateText = controller.selectedDate.value
                            .toString()
                            .split(' ')[0];
                        return Tooltip(
                          message: 'Date: $dateText',
                          child: Text(
                            dateText,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Next Day Icon
              GestureDetector(
                onTap: () {
                  final today = _toDateOnly(DateTime.now());
                  final nextDay = controller.selectedDate.value!
                      .add(const Duration(days: 1));

                  if (_toDateOnly(nextDay).isBefore(today)) {
                    controller.selectDate(nextDay);
                  }
                },
                child: SvgPicture.asset(
                  AppAssets.forwardIcon,
                  height: 18,
                  width: 18,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSampleCountCard() {
    final facility = controller.currentFacilityData.value;
    return Obx(() {
      if (!controller.dataFetched.value) {
        return const SizedBox.shrink();
      }

      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: controller.currentFacilityData.value?.count == 0
              ? Colors.orange[50]
              : Colors.green[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: controller.currentFacilityData.value?.count == 0
                ? Colors.orange[300]!
                : Colors.green[300]!,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  /* controller.currentFacilityData.value?.count == 0
                      ? Icons.file_present_outlined
                      : Icons.check_circle,*/
                  AppAssets.infoIcon,
                  color: controller.currentFacilityData.value?.count == 0
                      ? Colors.orange[600]
                      : Colors.green[600],
                  height: 16,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    controller.currentFacilityData.value?.count == 0
                        ? 'No samples recorded for this date\nया तारखेसाठी कोणतेही सॅम्पल नोंदवलेले नाहीत'
                        : 'Samples were collected on this date\nया तारखेसाठी सॅम्पल गोळा करण्यात आले आहेत',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                )
              ],
            ),
            if (facility?.count == 0) ...[
              if (facility?.remarByPhlebO.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.only(
                    top: 8.0,
                  ),
                  child: Text(
                    'Current Remark: ${facility?.remarByPhlebO}',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(
                    top: 8.0,
                  ),
                  child: Text(
                    'Please provide a reason for zero sample count\nकृपया शून्य सॅम्पल का आहेत ते कारण नमूद करा',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
            ]
          ],
        ),
      );
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate.value ??
          DateTime.now().subtract(const Duration(days: 1)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().subtract(
          const Duration(days: 1)), // Cannot select today or future dates
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      controller.selectDate(picked);
    }
  }

  DateTime _toDateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
