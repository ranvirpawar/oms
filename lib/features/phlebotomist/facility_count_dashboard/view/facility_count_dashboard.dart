import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/constants/app_assets.dart';
import 'package:lifenity_connect/routes/route_manager.dart';
import 'package:lifenity_connect/theme/app_colors.dart';
import 'package:lifenity_connect/utils/animated_shimmer/facility_card_shimmer.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';

import '../controller/facility_count_dashboard_controller.dart';
import '../model/facility_data_model.dart';

// Main Page
class FacilityRegistrationPage extends StatelessWidget {
  final FacilityController controller = Get.put(FacilityController());

   FacilityRegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: 'Patient Registration Dashboard',
        actions: [
          IconButton(
            onPressed: RouteManager.navigateToBagStatusDashboard,
            icon: SvgPicture.asset(
              AppAssets.patient,
              height: 26,
              colorFilter: ColorFilter.mode(
                Theme.of(Get.context!).colorScheme.onPrimary,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(
            width: 10,
          )
        ],
      ),
      body: Column(
        children: [
          _buildDateAndSummaryCard(),
          Expanded(child: _buildFacilityList()),
        ],
      ),
      floatingActionButton: _buildModernFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      // bottomNavigationBar: _buildModernFAB(),
    );
  }

  Widget _buildFacilityList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const FacilityCardShimmer();
      }

      if (controller.facilities.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No registrations found for the selected date.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        itemCount: controller.facilities.length,
        itemBuilder: (context, index) {
          return _buildFacilityCard(controller.facilities[index]);
        },
      );
    });
  }

  Widget _buildDateAndSummaryCard() {
    final FacilityController controller = Get.find<FacilityController>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
                  HapticFeedback.lightImpact();
                  final previousDay = controller.selectedDate.value
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
                  HapticFeedback.lightImpact();
                  final nextDay = controller.selectedDate.value
                      .add(const Duration(days: 1));
                  if (nextDay.isBefore(DateTime.now())) {
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
          Divider(
            color: Colors.grey[300],
            height: 20,
            thickness: 1,
          ),
          _buildSummaryCards(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Obx(() {
      final int totalPatients = controller.facilities
          .fold(0, (sum, facility) => sum + facility.totalRegistrationPatient);

      final int totalFacilities = controller.facilities.length;

      return Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Total\nFacilities',
              totalFacilities.toString(),
              AppColors.primary,
              AppAssets.facility,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildSummaryCard(
              'Total\nPatients',
              totalPatients.toString(),
              AppColors.tertiary900,
              AppAssets.patient,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSummaryCard(
      String title, String value, Color color, String icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(
            icon,
            color: color,
            height: 20,
            width: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2, // so your `\n` works but cuts off long words
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityCard(FacilityData facility) {
    return GestureDetector(
      onTap: () {
        RouteManager.navigateToPatientRegistrationList(
           facilityData:  facility, fromDate : controller.selectedDate.value);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Facility Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradientRev,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // facility icon
                  SvgPicture.asset(
                    AppAssets.facility,
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      facility.facilityName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2, // allow 2 lines
                      overflow: TextOverflow.ellipsis,
                      softWrap: true, // enable wrapping
                    ),
                  ),

                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${facility.totalRegistrationPatient} Patients',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Data Table
            Padding(
              padding: const EdgeInsets.all(0),
              child: Column(
                children: [
                  _buildDataTable(facility),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataTable(FacilityData facility) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1),
      },
      children: [
        // Header Row
        TableRow(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          children: [
            _buildTableHeader('Type'),
            _buildTableHeader('TRF'),
            _buildTableHeader('Tubes'),
          ],
        ),

        // P Row
        TableRow(
          children: [
            _buildTableCell('P (Phlebotomist)', Colors.green[600]!),
            _buildTableCell(facility.trfP?.toString() ?? '-'),
            _buildTableCell(facility.tubeCountP?.toString() ?? '-'),
          ],
        ),

        // R Row
        TableRow(
          decoration: BoxDecoration(
            color: Colors.grey[25],
          ),
          children: [
            _buildTableCell('R (Runner-Boy)', Colors.orange[600]!),
            _buildTableCell(facility.trfR?.toString() ?? '-'),
            _buildTableCell(facility.tubeCountR?.toString() ?? '-'),
          ],
        ),

        // L Row
        TableRow(
          children: [
            _buildTableCell('L (Lab-Accession)', Colors.purple[600]!),
            _buildTableCell(facility.trfCountL?.toString() ?? '-'),
            _buildTableCell(facility.tubeCountL?.toString() ?? '-'),
          ],
        ),
      ],
    );
  }

  Widget _buildTableHeader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: Colors.grey[700],
        ),
        textAlign: TextAlign.start,
      ),
    );
  }

  Widget _buildTableCell(String text, [Color? labelColor]) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          if (labelColor != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: labelColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: labelColor ?? Colors.grey[800],
                fontWeight:
                    labelColor != null ? FontWeight.w500 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != controller.selectedDate.value) {
      controller.selectDate(picked);
    }
  }

  Widget _buildModernFAB() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: RouteManager.navigateToBagStatusDashboard,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                AppAssets.patient,
                color: Theme.of(Get.context!).colorScheme.onPrimary,
                height: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Patient Registration',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(Get.context!).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
