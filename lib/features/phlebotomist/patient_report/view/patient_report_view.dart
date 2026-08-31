import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lifenity_connect/componenents/cdateformpicker_field.dart';
import 'package:lifenity_connect/features/team_lead/visit_details/view/widgets/custom_dropdown.dart';
import 'package:lifenity_connect/utils/helper_functions/helper_methods.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';

import '../../../../constants/app_assets.dart';
import '../../../../constants/app_strings.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/animated_shimmer/patient_report_shimmer.dart';
import '../../../../utils/widgets/modern_dropdown.dart';
import '../controller/patient_report_controller.dart';
import '../model/patiet_report_data.dart';

class PatientReportView extends StatelessWidget {
  PatientReportView({super.key});

  final PatientReportController controller = Get.put(PatientReportController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: const CustomAppBar(title: AppStrings.patientReport),
      body: Obx(() {
        if (controller.initialLoading.value) {
          return const PatientReportShimmer();
        }
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              // Animated Search Section
              _buildCollapsedSearchSection(context),

              // Search Box for filtering reports
              Obx(
                () => controller.patientReports.isNotEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            /*borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),*/
                          ),
                          child: TextField(
                            controller: controller.searchController,
                            onChanged: (value) =>
                                controller.filterReports(value),
                            decoration: InputDecoration(
                              hintText: 'Search by name, mobile, or barcode...',
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey[600],
                                size: 16,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              hintStyle: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              const SizedBox(height: 16),

              // Reports List
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.filteredReports.isEmpty &&
                      controller.patientReports.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No reports found matching your search',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  if (controller.patientReports.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No reports found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Scrollbar(
                    radius: const Radius.circular(16),
                    child: ListView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: controller.filteredReports.length,
                      itemBuilder: (context, index) {
                        // Reverse the index to show items in reverse order
                        final reversedIndex =
                            controller.filteredReports.length - 1 - index;
                        final report =
                            controller.filteredReports[reversedIndex];
                        return _buildReportCard(context, report, index + 1);
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCollapsedSearchSection(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                FocusScope.of(context).unfocus();
                controller.toggleSearchExpansion();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Obx(
                  () => AnimatedCrossFade(
                    duration: const Duration(milliseconds: 200),
                    crossFadeState: controller.isSearchExpanded.value
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: _buildCollapsedContent(context),
                    secondChild: _buildExpandedContent(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedContent(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SvgPicture.asset(
            AppAssets.fileNoteIcon,
            color: Theme.of(context).primaryColor,
            height: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                controller.selectedFacilityName.value?.facilityName ??
                    AppStrings.selectFacility,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                _getDateRangeText(),
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${controller.filteredReports.length} reports',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        AnimatedRotation(
          turns: controller.isSearchExpanded.value ? 0.5 : 0,
          duration: const Duration(milliseconds: 200),
          child: Icon(Icons.expand_more, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    return Column(
      children: [
        // Header with close button
        Row(
          children: [
            Text(
              AppStrings.search,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () => controller.toggleSearchExpansion(),
              icon: const Icon(Icons.close),
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ModernDropdown(
                label: AppStrings.labName,
                value: controller.selectedLabName.value?.centerName ?? ' ',
                items: controller.labNames.map((e) => e.centerName).toList(),
                onChanged: (value) {
                  final selectedLab = controller.labNames.firstWhere(
                    (lab) => lab.centerName == value,
                    orElse: () => controller.labNames.first,
                  );
                  debugPrint(
                    'Selected Lab: ${selectedLab.centerName}, code: ${selectedLab.centerId}',
                  );
                  controller.selectedLabName.value = selectedLab;
                },
                iconPath: AppAssets.laboratory,
                isRequired: true,
              ),
              if (controller.labInfoError.value.isNotEmpty &&
                  controller.selectedLabName.value == null)
                const Padding(
                  padding: EdgeInsets.only(top: 4.0, left: 8.0),
                  child: Text(
                    'Please select lab name',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Facility name dropdown
        Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomDropdown(
                label: AppStrings.facilityName,
                value:
                    controller.selectedFacilityName.value?.facilityName ?? '',
                items: controller.facilityNames
                    .map((e) => e.facilityName)
                    .toList(),
                onChanged: (value) {
                  if (value != null && value.isNotEmpty) {
                    final selectedFacility = controller.facilityNames
                        .firstWhere(
                          (facility) => facility.facilityName == value,
                        );
                    controller.selectedFacilityName.value = selectedFacility;
                    debugPrint(
                      'Selected Facility: ${selectedFacility.facilityName}, code: ${selectedFacility.facilityId}',
                    );
                  }
                },
                iconPath: AppAssets.facility,
                isRequired: true,
              ),

              if (controller.labInfoError.value.isNotEmpty &&
                  controller.selectedFacilityName.value == null)
                const Padding(
                  padding: EdgeInsets.only(top: 4.0, left: 8.0),
                  child: Text(
                    AppStrings.facilityNameError,
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Date Pickers Row
        Row(
          children: [
            Expanded(
              child: Obx(
                () => CFormDateField(
                  label: 'From Date',
                  value: controller.fromDate.value != null
                      ? '${controller.fromDate.value!.day}/${controller.fromDate.value!.month}/${controller.fromDate.value!.year}'
                      : '',
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: Get.context!,
                      initialDate: controller.fromDate.value ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      // Earliest selectable date from 2000
                      lastDate: DateTime.now(),
                      // No future dates
                      initialEntryMode: DatePickerEntryMode.calendarOnly,
                    );
                    if (picked != null) {
                      controller.fromDate.value = picked;

                      // Auto-set To Date when From Date changes
                      if (controller.toDate.value != null &&
                          (controller.toDate.value!.isBefore(picked) ||
                              controller.toDate.value!
                                      .difference(picked)
                                      .inDays >
                                  7)) {
                        // Set To Date to 7 days after From Date or today, whichever is earlier
                        final defaultToDate = picked.add(
                          const Duration(days: 7),
                        );
                        controller.toDate.value =
                            defaultToDate.isAfter(DateTime.now())
                            ? DateTime.now()
                            : defaultToDate;
                      }

                      // If no To Date is set, initialize it
                      if (controller.toDate.value == null) {
                        final defaultToDate = picked.add(
                          const Duration(days: 7),
                        );
                        controller.toDate.value =
                            defaultToDate.isAfter(DateTime.now())
                            ? DateTime.now()
                            : defaultToDate;
                      }
                    }
                  },
                  iconPath: AppAssets.calendarIcon,
                  isRequired: true,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Obx(
                () => CFormDateField(
                  label: 'To Date',
                  value: controller.toDate.value != null
                      ? '${controller.toDate.value!.day}/${controller.toDate.value!.month}/${controller.toDate.value!.year}'
                      : '',
                  onTap: () async {
                    // Calculate the maximum allowed "To Date"
                    DateTime maxToDate = DateTime.now();
                    if (controller.fromDate.value != null) {
                      // Get the date that is 7 days from "From Date"
                      final DateTime sevenDaysFromFromDate = controller
                          .fromDate
                          .value!
                          .add(const Duration(days: 7));
                      // Use whichever is earlier: today or 7 days from "From Date"
                      maxToDate = sevenDaysFromFromDate.isBefore(DateTime.now())
                          ? sevenDaysFromFromDate
                          : DateTime.now();
                    }

                    final DateTime? picked = await showDatePicker(
                      context: Get.context!,
                      initialDate:
                          controller.toDate.value ??
                          (controller.fromDate.value ?? DateTime.now()),
                      firstDate: controller.fromDate.value ?? DateTime(2000),
                      lastDate: maxToDate,
                      // ✅ FIX: Cap at today or 7 days from fromDate, whichever is earlier
                      initialEntryMode: DatePickerEntryMode.calendarOnly,
                    );

                    if (picked != null) {
                      controller.toDate.value = picked;

                      // Ensure To Date is not before From Date
                      if (controller.fromDate.value != null &&
                          picked.isBefore(controller.fromDate.value!)) {
                        controller.toDate.value = controller.fromDate.value;
                      }
                    }
                  },
                  iconPath: AppAssets.calendarIcon,
                  isRequired: true,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Action buttons
        Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () {
                  controller.clearFilters();
                  controller.toggleSearchExpansion();
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[400]!),
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(AppStrings.clear),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () {
                  if (controller.selectedLabName.value == null ||
                      controller.selectedLabName.value!.centerName.isEmpty ||
                      controller.selectedFacilityName.value == null ||
                      controller
                          .selectedFacilityName
                          .value!
                          .facilityName
                          .isEmpty) {
                    controller.labInfoError.value = 'Please select a lab';
                    controller.facilityInfoError.value =
                        'Please select a facility';

                    return;
                  }
                  controller.fetchPatientReports();
                  controller.toggleSearchExpansion();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(AppStrings.applyFilter),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getDateRangeText() {
    final from = controller.fromDate.value;
    final to = controller.toDate.value;

    if (from != null && to != null) {
      return '${DateFormat('dd/MM').format(from)} - ${DateFormat('dd/MM').format(to)}';
    } else if (from != null) {
      return 'From ${DateFormat('dd/MM/yy').format(from)}';
    } else if (to != null) {
      return 'Until ${DateFormat('dd/MM/yy').format(to)}';
    }
    return 'Select date range';
  }

  Widget _buildReportCard(
    BuildContext context,
    PatientReportData report,
    int srNo,
  ) {
    final bool isReportReady = (report.reportReadyCount) > 0;
    final theme = Theme.of(context);

    return Stack(
      children: [
        Column(
          children: [
            const SizedBox(height: 10),

            // Main card - Ultra Compact
            // allow copy the text elements from this widget to clipboard
            InkWell(
              onTap: () {
                print('🎯 Report card tapped for barcode ${report.barcode}');
                controller.onReportCardTap(report);
              },
              splashColor: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),

              child: Container(
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
                        colors: [Colors.white, Colors.grey.shade50],
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
                                      width: 16,
                                      height: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        HelperMethods.capitalizeFirstLetter(
                                          report.patientName ?? 'N/A',
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: AppColors.textPrimary,
                                        ),
                                        softWrap: true,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Row(
                                  children: [
                                    isReportReady
                                        ? SvgPicture.asset(
                                            AppAssets.whatsAppIcon,
                                            width: 16,
                                            height: 16,
                                            color: AppColors.emerald700,
                                          )
                                        : SvgPicture.asset(
                                            AppAssets.mobileIcon,
                                            width: 16,
                                            height: 16,
                                            color: AppColors.primary,
                                          ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: isReportReady
                                          ? () =>
                                                controller.handleWhatsAppShare(
                                                  report,
                                                  report.mobile,
                                                )
                                          : null,
                                      // Disable tap if report is not ready
                                      child: Text(
                                        report.mobile ?? 'N/A',

                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          color: isReportReady
                                              ? AppColors.emerald700
                                              : AppColors.textPrimary,
                                          /*decoration: TextDecoration.underline,*/
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          // visit date and barcode
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    SvgPicture.asset(
                                      AppAssets.barcodeIcon,
                                      width: 16,
                                      height: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        report.barcode ?? 'N/A',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          color: AppColors.textPrimary,
                                        ),
                                        /*    softWrap: true,
                                        overflow: TextOverflow.ellipsis,*/
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Row(
                                  children: [
                                    SvgPicture.asset(
                                      AppAssets.calendarIcon,
                                      width: 16,
                                      height: 16,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      report.visitDate ?? 'N/A',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Bottom Row - Counts + Actions
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Test Counts - Ultra Compact
                              _buildMiniChip(
                                report.totalTestCount.toString() ?? '0',
                                AppColors.primary,
                                AppStrings.tests,
                              ),
                              const SizedBox(width: 6),
                              isReportReady
                                  ? _buildMiniChip(
                                      report.reportReadyCount.toString() ?? '0',
                                      isReportReady
                                          ? AppColors.emerald600
                                          : AppColors.tertiary900,
                                      AppStrings.ready,
                                    )
                                  : const SizedBox.shrink(),

                              const Spacer(),

                              // Action Buttons - Only if Ready
                              if (isReportReady) ...[
                                _buildCompactButton(
                                  Icons.visibility_rounded,
                                  AppColors.tertiary900,
                                  () => controller.viewReport(report),
                                  AppStrings.view,
                                ),
                                const SizedBox(width: 6),
                                Obx(() {
                                  return _buildCompactButton(
                                    Icons.share_rounded,
                                    AppColors.tertiary900,
                                    () => controller.shareReport(report),
                                    AppStrings.share,
                                    isDisabled:
                                        (controller.shareBtnLoadingStates[report
                                                    .barcode] ??
                                                false)
                                            .obs, // Fallback to false if barcode is null
                                  );
                                }),
                              ] else ...[
                                // Pending Status - Mini
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.secondary200,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.access_time_rounded,
                                        color: AppColors.secondary700,
                                        size: 12,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        AppStrings.pending,
                                        style: TextStyle(
                                          color: AppColors.secondary700,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          left: 4,
          top: 0,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                srNo.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniChip(String count, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 0.5),
      ),
      child: Text(
        '$label : $count',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCompactButton(
    IconData icon,
    Color color,
    VoidCallback onPressed,
    String label, {
    RxBool? isDisabled, // Optional reactive boolean for disabled/loading state
  }) {
    Widget buildButtonContent(bool disabled) {
      final Color effectiveColor = disabled ? Colors.grey.shade400 : color;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        decoration: BoxDecoration(
          color: effectiveColor.withOpacity(disabled ? 0.05 : 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: effectiveColor.withOpacity(disabled ? 0.1 : 0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (disabled)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: effectiveColor,
                ),
              )
            else ...[
              Icon(icon, size: 16, color: effectiveColor),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: effectiveColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      );
    }

    if (isDisabled != null) {
      return Obx(
        () => GestureDetector(
          onTap: isDisabled.value ? null : onPressed,
          // Disable tap when loading
          child: buildButtonContent(isDisabled.value),
        ),
      );
    }

    // Non-reactive case (e.g., for view button)
    return GestureDetector(onTap: onPressed, child: buildButtonContent(false));
  }
}
