import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/utils/animations/animated_tap_scale.dart';

import '../../../constants/app_assets.dart';
import '../../../routes/route_manager.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/health_card_colors.dart';
import '../../../utils/animated_shimmer/summary_shimmer_class.dart';
import '../../../utils/widgets/custom_appbar.dart';
import '../controller/facility_list_controller.dart';
import '../model/facility_type_model.dart';

class FacilityListPage extends StatelessWidget {
  final FacilityTypeModel facilityType;
  final DateTime fromDate;
  final DateTime toDate;

  FacilityListPage({
    super.key,
    required this.facilityType,
    required this.fromDate,
    required this.toDate,
  }) {
    // Initialize controller with data
    final controller = Get.put(FacilityListController());
    controller.initialize(facilityType, fromDate, toDate);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FacilityListController>();

    return Scaffold(
      appBar: CustomAppBar(
        title: facilityType.fType,
        actions: const [],
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const FacilityListPageSkeleton();
        }

        return RefreshIndicator(
          onRefresh: controller.refreshData,
          child: CustomScrollView(
            slivers: [
              // Date Selection Widget
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: _buildDateSelector(controller, context),
                ),
              ),

              // Search Bar and Filters
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildSearchBar(controller),
                      const SizedBox(height: 12),
                      _buildSortOptions(controller),
                    ],
                  ),
                ),
              ),

              // Stats Header
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverToBoxAdapter(
                  child: _buildStatsHeader(controller),
                ),
              ),

              // Facility List
              if (controller.filteredFacilities.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          controller.searchQuery.value.isEmpty
                              ? 'No facilities found'
                              : 'No results for "${controller.searchQuery.value}"',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final facility = controller.filteredFacilities[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildFacilityCard(facility, index + 1, controller),
                        );
                      },
                      childCount: controller.filteredFacilities.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDateSelector(
      FacilityListController controller, BuildContext context) {
    return AnimatedTapScale(
      child: InkWell(
        onTap: () => controller.selectDateRange(context),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SvgPicture.asset(
                  AppAssets.calendarIcon,
                  width: 20,
                  height: 20,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF6366F1),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date Range',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      controller.dateRangeText,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF9CA3AF),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(FacilityListController controller) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: controller.updateSearchQuery,
        decoration: InputDecoration(
          hintText: 'Search facilities...',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey.shade400,
            size: 20,
          ),
          suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                  onPressed: () => controller.updateSearchQuery(''),
                )
              : const SizedBox.shrink()),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSortOptions(FacilityListController controller) {
    return Row(
      children: [
        const Text(
          'Sort by:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSortChip(controller, 'Name', 'name'),
                const SizedBox(width: 8),
                _buildSortChip(controller, 'Patients', 'patients'),
                const SizedBox(width: 8),
                _buildSortChip(controller, 'Tests', 'tests'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSortChip(
      FacilityListController controller, String label, String value) {
    return Obx(() {
      final isSelected = controller.sortBy.value == value;
      return InkWell(
        onTap: () => controller.updateSorting(value),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                Icon(
                  controller.isAscending.value
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  size: 12,
                  color: Colors.white,
                ),
              ],
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatsHeader(FacilityListController controller) {
    final totalPatients = controller.filteredFacilities.fold<int>(
      0,
      (sum, facility) => sum + facility.patientCount,
    );
    final totalTests = controller.filteredFacilities.fold<int>(
      0,
      (sum, facility) => sum + facility.testCount,
    );
    final totalFacilities = controller.filteredFacilities.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                AppAssets.fileNoteIcon,
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF6366F1),
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Overview Statistics',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Facilities',
                  totalFacilities.toString(),
                  AppAssets.facility,
                  const Color(0xFF6366F1),
                  const Color(0xFFEEF2FF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Patients',
                  _formatNumber(totalPatients),
                  AppAssets.patient,
                  HealthCardColors.bloodPressure,
                  HealthCardColors.bloodPressure50,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Tests',
                  _formatNumber(totalTests),
                  AppAssets.testTube,
                  AppColors.hmisPrimary,
                  const Color(0xFFECFDF5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, String iconAsset,
      Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          SvgPicture.asset(
            iconAsset,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              color,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityCard(FacilityModel facility, int index, controller) {
    return AnimatedTapScale(
      child: GestureDetector(
        onTap: () {
          RouteManager.navigateToPatientRegistrationList(
              facilityData: facility,fromDate: controller.fromDate, toDate: controller.toDate );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
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
              // First Row: Sr No and Name
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFF6366F1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$index',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        facility.facilityName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Second Row: Patient and Test Data
              Row(
                children: [
                  Expanded(
                    child: _buildCompactMetric(
                      'Patients',
                      _formatNumber(facility.patientCount),
                      AppAssets.patient,
                      HealthCardColors.bloodPressure,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildCompactMetric(
                      'Tests',
                      _formatNumber(facility.testCount),
                      AppAssets.testTube,
                      AppColors.hmisPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactMetric(
      String label, String value, String iconAsset, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            iconAsset,
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(
              color,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: color.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
