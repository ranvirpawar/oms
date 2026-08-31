import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lifenity_connect/componenents/c_textformfeild.dart';
import 'package:lifenity_connect/features/team_lead/invoice_tracking/controller/invoice_tracking_controller.dart';
import 'package:lifenity_connect/features/team_lead/invoice_tracking/view/widget/invoice_file_upload_widget.dart';
import 'package:lifenity_connect/utils/animated_shimmer/invoice_tracking_view_shimmer.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';

import '../../../../constants/app_assets.dart';
import '../../../../constants/app_strings.dart';
import 'package:get/get.dart';

import '../../../../theme/app_colors.dart';
import '../../../../utils/widgets/modern_dropdown.dart';
import '../../visit_details/view/widgets/custom_dropdown.dart';


class InvoiceTrackingView extends StatelessWidget {
  final InvoiceTrackingController controller =
      Get.put(InvoiceTrackingController());

  InvoiceTrackingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: AppStrings.invoiceTracking),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const InvoiceTrackingShimmer();
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Ward and Facility Type Dropdown Row
              Row(
                children: [
                  // Ward Dropdown
                  Expanded(
                    child: Obx(
                      () => ModernDropdown(
                        label: 'Ward',
                        value: controller.selectedWard.value,
                        items: controller.wards,
                        onChanged: controller.onWardChanged,
                        placeholder: controller.wards.isEmpty
                            ? 'Loading...'
                            : 'Select Ward',
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Facility Type Dropdown
                  Expanded(
                    child: Obx(
                      () => ModernDropdown(
                        label: 'Facility Type',
                        value:
                            controller.selectedFacilityType.value?.fTypeName ??
                            '',
                        items: controller.facilityTypes
                            .map((t) => t.fTypeName)
                            .toList(),
                        onChanged: controller.onFacilityTypeChanged,
                        placeholder: controller.facilityTypes.isEmpty
                            ? 'Loading...'
                            : 'Select Type',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Obx(() {
                return CustomDropdown(
                  label: 'Facility Name',
                  value:
                      controller.selectedFacilityName.value?.facilityName ?? '',
                  items: controller.facilityNames
                      .map((f) => f.facilityName)
                      .toList(),
                  onChanged: controller.onFacilityNameChanged,
                  isRequired: true,
                  placeholder: controller.isFacilityLoading.value
                      ? 'Loading facilities...'
                      : controller.selectedWard.value.isEmpty
                      ? 'Select Ward First'
                      : controller.selectedFacilityType.value == null
                      ? 'Select Facility Type'
                      : controller.facilityNames.isEmpty
                      ? 'No facilities found'
                      : 'Select Facility',
                  suffix: controller.isFacilityLoading.value
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                );
              }),
              const SizedBox(height: 16),

              // Year and Month Row
              Row(
                children: [
                  // Year Dropdown - UPDATED to use new method
                  Expanded(
                    child: Obx(
                      () => ModernDropdown(
                        isRequired: true,
                        iconPath: AppAssets.calendarIcon,
                        label: 'Year',
                        value:
                            controller.selectedYear.value?.year.toString() ??
                            '',
                        items: controller.years
                            .map((y) => y.year.toString())
                            .toList(),
                        onChanged: (value) {
                          controller.onYearChanged(value!);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Month Dropdown
                  Expanded(
                    child: Obx(
                      () => ModernDropdown(
                        isRequired: true,
                        iconPath: AppAssets.calendarIcon,
                        label: 'Month',
                        value:
                            controller.selectedMonth.value?.monthNameEng ?? '',
                        items: controller.months
                            .map((m) => m.monthNameEng)
                            .toList(),
                        onChanged: (value) {
                          final month = controller.months.firstWhere(
                            (m) => m.monthNameEng == value,
                          );
                          controller.selectedMonth.value = month;
                          debugPrint('✅ Selected Month: ${month.monthNameEng}');
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Search Button
              Obx(
                () => ElevatedButton.icon(
                  onPressed: controller.isSearching.value
                      ? null
                      : controller.searchInvoices,
                  icon: controller.isSearching.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.search),
                  label: Text(
                    controller.isSearching.value
                        ? 'Searching...'
                        : 'Search Invoices',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Invoice List
              Obx(() {
                if (controller.invoiceList.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Invoice Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Invoice Cards - UPDATED to use toggle method
                    ...controller.invoiceList.map((invoice) {
                      final isSelected =
                          controller.selectedInvoice.value?.invoiceId ==
                          invoice.invoiceId;

                      return GestureDetector(
                        onTap: () {
                          // haptic feedback
                          HapticFeedback.lightImpact();
                          // Toggle selection
                          controller.toggleInvoiceSelection(invoice);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Card(
                                elevation: isSelected ? 0 : 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              invoice.facilityName,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Chip(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 0,
                                              vertical: 0,
                                            ),
                                            label: Text(
                                              invoice.fType,
                                              style: const TextStyle(
                                                fontSize: 10,
                                              ),
                                            ),
                                            backgroundColor: AppColors.primary,
                                            labelStyle: const TextStyle(
                                              color: Colors.white,
                                            ),
                                            labelPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 4,
                                                  vertical: 1,
                                                ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      _buildInfoRow(
                                        'Invoice Number',
                                        invoice.invoiceNumber,
                                      ),
                                      _buildInfoRow(
                                        'Current Status',
                                        invoice.processDescription,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Check icon badge - positioned half inside, half outside
                              if (isSelected)
                                Positioned(
                                  top: -8,
                                  right: -8,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                    /*...controller.invoiceList.map((invoice) => Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        invoice.facilityName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Chip(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 0, vertical: 0),
                                      label: Text(
                                        invoice.fType,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      backgroundColor: AppColors.primary,
                                      labelStyle: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      labelPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                      shape: RoundedRectangleBorder(

                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      // change border color



                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildInfoRow(
                                    'Invoice Number', invoice.invoiceNumber),
                                _buildInfoRow('Current Status',
                                    invoice.processDescription),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    controller.toggleInvoiceSelection(invoice);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    minimumSize:
                                        const Size(double.infinity, 40),
                                    backgroundColor: controller.selectedInvoice
                                                .value?.invoiceId ==
                                            invoice.invoiceId
                                        ? Colors.green
                                        : Theme.of(context).primaryColor,
                                  ),
                                  child: Text(
                                    controller.selectedInvoice.value
                                                ?.invoiceId ==
                                            invoice.invoiceId
                                        ? 'Selected'
                                        : 'Select Invoice',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),*/
                  ],
                );
              }),

              // Stage Dropdown (shown only when invoice is selected)
              Obx(() {
                if (controller.selectedInvoice.value == null) {
                  return const SizedBox.shrink();
                }
                if (controller.stages.isEmpty) {
                  // return container showing invoice status is update
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Invoice status for selected facility is updated',
                            style: TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    const Text(
                      'Update Invoice Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    /*CustomDropdown(
                      isRequired: true,
                      iconPath: AppAssets.fileNoteIcon,
                      label: "Select Status",
                      value:
                          controller.selectedStage.value?.processDescription ??
                              '',
                      items: controller.stages
                          .map((s) => s.processDescription)
                          .toList(),
                      onChanged: (value) {
                        final stage = controller.stages.firstWhere(
                          (s) => s.processDescription == value,
                        );

                        // 🚫 Block BR stage if user is not Team Lead
                        if (stage.processId == 24 &&
                            !controller.isTeamLeadLogin.value) {
                          SnackBarService.to.showMessage(
                              message:
                                  'You are not authorized to update this stage.');

                          // 🔄 Revert dropdown to previous selected value
                          // Trigger refresh manually
                          controller.selectedStage.refresh();
                          return;
                        }

                        // ✅ Allowed: update normally
                        controller.selectedStage.value = stage;

                        // Clear file and BR number
                        controller.clearFile();
                        controller.brNumber.value = '';

                        debugPrint(
                            '✅ Selected Stage: ${stage.processDescription}, ID: ${stage.processId}');
                      },
                    ),*/
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        controller.showStageSelectionBottomSheet();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primary),
                          borderRadius: BorderRadius.circular(8),
                          color: AppColors.primary.withOpacity(0.01),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.list_alt_rounded,
                                color: AppColors.primary,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    controller.selectedStage.value == null
                                        ? 'Select Next Status'
                                        : 'Selected Status',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    controller
                                            .selectedStage
                                            .value
                                            ?.processDescription ??
                                        'Tap to view available stages',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          controller.selectedStage.value == null
                                          ? Colors.grey.shade700
                                          : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),

                    /* // Show selected stage info
                    Obx(() {
                      if (controller.selectedStage.value == null) {
                        return const SizedBox.shrink();
                      }

                      return Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          border: Border.all(color: Colors.green.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green.shade700,
                                size: 20
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Stage ID: ${controller.selectedStage.value!.processId}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.green.shade900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),*/

                    // File Upload Section (shown for specific stages)
                    Obx(() {
                      if (!controller.shouldShowFileUpload()) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        children: [
                          const SizedBox(height: 16),
                          InvoiceFileUploadWidget(
                            selectedImageFiles: controller.selectedImageFiles,
                            selectedPdfFile: controller.selectedFile,
                            selectedPdfFileName: controller.selectedFileName,
                            onAddImages: controller.showImageSourceSelection,
                            onAddPdf: controller.pickFile,
                            onRemoveImage: (index) =>
                                controller.removeImageFile(index),
                            onRemovePdf: controller.clearFile,
                          ),
                        ],
                      );
                    }),

                    // BR Number Input (shown for stage 24) only for team lead login
                    Obx(() {
                      if (!controller.shouldShowBRNumber()) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          CFormTextField(
                            label: 'BR Number',
                            iconPath: AppAssets.fileNoteIcon,
                            onChanged: (value) {
                              controller.brNumber.value = value;
                            },
                            maxLength: 50,
                            isRequired: false,
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 24),

                    // Submit Button
                    Obx(
                      () => ElevatedButton.icon(
                        onPressed: controller.isSubmitting.value
                            ? null
                            : controller.submitInvoiceStatus,
                        icon: controller.isSubmitting.value
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          controller.isSubmitting.value
                              ? 'Submitting...'
                              : 'Submit',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),

                    // sizedbox
                    const SizedBox(height: 30),
                  ],
                );
              }),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _getFacilityPlaceholder({
    required InvoiceTrackingController controller,
    required int filteredCount,
  }) {
    if (controller.wards.isEmpty || controller.facilityTypes.isEmpty) {
      return 'Loading...';
    }
    if (controller.selectedWard.value.isEmpty) {
      return 'Select Ward First';
    }
    if (controller.selectedFacilityType.value == null) {
      return 'Select Facility Type';
    }
    if (filteredCount == 0) {
      return 'No facilities available';
    }
    return 'Select Facility';
  }
}
