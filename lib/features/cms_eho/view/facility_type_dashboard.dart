import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/utils/animations/animated_tap_scale.dart';

import '../../../constants/app_assets.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/health_card_colors.dart';
import '../../../utils/animated_shimmer/summary_shimmer_class.dart';
import '../../../utils/widgets/custom_appbar.dart';
import '../controller/facility_type_controller.dart';
import '../model/facility_type_model.dart';
import 'facility_list_page.dart';

class FacilityTypeDashboard extends StatelessWidget {
  final FacilityTypeController controller = Get.put(FacilityTypeController());

  FacilityTypeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Facility Wise Summary Dashboard',
        actions: [],
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const FacilityTypeDashboardSkeleton();
        }


        return RefreshIndicator(
          onRefresh: controller.refreshData,
          child: CustomScrollView(
            slivers: [
              // Date Range Selector
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                sliver: SliverToBoxAdapter(
                  child:
                      AnimatedTapScale(child: _buildDateRangeSelector(context)),
                ),
              ),

              // Search Bar
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverToBoxAdapter(
                  child: _buildSearchBar(),
                ),
              ),

              // Summary Stats
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverToBoxAdapter(
                  child: _buildSummaryStats(),
                ),
              ),

              // Facility Types List
              if (controller.filteredFacilityTypes.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          controller.searchQuery.value.isEmpty
                              ? 'No facility types found'
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
                        final facilityType =
                            controller.filteredFacilityTypes[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildFacilityTypeCard(facilityType, context),
                        );
                      },
                      childCount: controller.filteredFacilityTypes.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDateRangeSelector(BuildContext context) {
    return Obx(() => Padding(
          padding: const EdgeInsets.all(0),
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
                mainAxisSize: MainAxisSize.min,
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
        ));
  }


  Widget _buildSearchBar() {
    return Container(
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
      child: TextField(
        onChanged: controller.updateSearchQuery,
        decoration: InputDecoration(
          hintText: 'Search facility types...',
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

  Widget _buildSummaryStats() {
    final totalPatients = controller.filteredFacilityTypes.fold<int>(
      0,
      (sum, type) => sum + type.patientCount,
    );

    final totalTests = controller.filteredFacilityTypes.fold<int>(
      0,
      (sum, type) => sum + type.testCount,
    );
    final totalTypes = controller.filteredFacilityTypes.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
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
          const Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                color: Color(0xFF64748B),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Summary Overview',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Types',
                  totalTypes.toString(),
                  Icons.notes,
                  HealthCardColors.spo2900,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  'Patients',
                  _formatNumber(totalPatients),
                  Icons.people_outline,
                  HealthCardColors.bloodPressure700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  'Tests',
                  _formatNumber(totalTests),
                  Icons.science_outlined,
                   HealthCardColors.bloodSugar700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityTypeCard(
      FacilityTypeModel facilityType, BuildContext context) {
    return AnimatedTapScale(

      child: Material(
        elevation: 0,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            Get.to(() => FacilityListPage(
                  facilityType: facilityType,
                  fromDate: controller.fromDate.value,
                  toDate: controller.toDate.value,
                ),
            transition: Transition.circularReveal,);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First Row: Icon, Name, and Suffix Icon
                Row(
                  children: [
                    // Facility Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: SvgPicture.asset(
                        AppAssets.facility,
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(
                          AppColors.primary,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
      
                    // Facility Name
                    Expanded(
                      child: Text(
                        facilityType.fType,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
      
                    // Arrow Icon
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
      
                const SizedBox(height: 12),
      
                // Second Row: Metric Badges
                Row(
                  children: [
                    // Patients Count
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color:    HealthCardColors.bloodPressure700.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:   HealthCardColors.bloodPressure700.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              AppAssets.patient,
                              width: 16,
                              height: 16,
                              colorFilter: const ColorFilter.mode(
                                HealthCardColors.bloodPressure700,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatNumber(facilityType.patientCount),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color:   HealthCardColors.bloodPressure700,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Text(
                              'Patients',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color:   HealthCardColors.bloodPressure700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
      
                    const SizedBox(width: 8),
      
                    // Tests Count
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color:  HealthCardColors.bloodSugar700.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:  HealthCardColors.bloodSugar700.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              AppAssets.testTube,
                              width: 16,
                              height: 16,
                              colorFilter: const ColorFilter.mode(
                                HealthCardColors.bloodSugar700,
                                BlendMode.srcIn,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatNumber(facilityType.testCount),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: HealthCardColors.bloodSugar700,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Text(
                              'Tests',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: HealthCardColors.bloodSugar700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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
