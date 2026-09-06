import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_registration/bag_status_dashboard/view/widget/collected_order_card.dart';

import '../../../../../componenents/c_textformfeild.dart';
import '../../../../../constants/app_assets.dart';
import '../../../../../constants/app_strings.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../utils/widgets/custom_appbar.dart';
import '../../../../../utils/widgets/modern_dropdown.dart';
import '../controller/patient_list_controller.dart';
import '../model/active_bag_model.dart';

class CollectedOrdersList extends StatelessWidget {
  const CollectedOrdersList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PatientListController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: AppStrings.collectedOrders,


        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.surfaceContainer),
            onPressed: () => controller.refresh(),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingBags.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          );
        }

        if (controller.activeBagSessions.isEmpty) {
          return _buildEmptyBagsState();
        }

        return RefreshIndicator(
          onRefresh: controller.refresh,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bag Dropdown
                _buildBagDropdown(controller),
                const SizedBox(height: 16),

                // Search Bar
                _buildSearchBar(controller),
                const SizedBox(height: 20),

                // Patient List
                _buildPatientList(controller),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ─── Bag Dropdown ─────────────────────────────────────────────────────────

  Widget _buildBagDropdown(PatientListController controller) {
    return Obx(
          () => ModernDropdown(
        label: 'Select Bag',
        // Will show pre-selected bagcode from dashboard automatically
        value: controller.selectedSession.value?.bagcode ?? ' ',
        items: controller.activeBagSessions.map((e) => e.bagcode).toList(),
        onChanged: (value) {
          final selected = controller.activeBagSessions.firstWhere(
                (s) => s.bagcode == value,
            orElse: () => controller.activeBagSessions.first,
          );
          controller.onBagSelected(selected);
        },
        iconPath: AppAssets.medicalUnitIcon,
        isRequired: true,
      ),
    );
  }

  // ─── Search Bar ───────────────────────────────────────────────────────────

  Widget _buildSearchBar(PatientListController controller) {
    return CFormTextField(
      controller: controller.searchTextController,
      label: 'Search by name or barcode',
      iconPath: AppAssets.userIcon, // your svg asset
      keyboardType: TextInputType.text,
      onChanged: controller.onSearchChanged,
    );
  }

  // ─── Patient List ─────────────────────────────────────────────────────────

  Widget _buildPatientList(PatientListController controller) {
    if (controller.isLoadingPatients.value) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );
    }

    if (controller.filteredPatientList.isEmpty) {
      return _buildEmptyPatientsState(
          controller.searchQuery.value.isNotEmpty);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12, left: 2),
          child: Text(
            '${controller.filteredPatientList.length} of ${controller.patientList.length} Patient${controller.patientList.length != 1 ? 's' : ''}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF718096),
            ),
          ),
        ),
        ...controller.filteredPatientList.asMap().entries.map((entry) {
          return CollectedOrderCard(order: entry.value, );
        }),
      ],
    );
  }



  // ─── Empty States ─────────────────────────────────────────────────────────

  Widget _buildEmptyBagsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF4299E1).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                AppAssets.medicalUnitIcon,
                width: 48,
                height: 48,
                colorFilter: const ColorFilter.mode(
                    Color(0xFF4299E1), BlendMode.srcIn),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Active Bags Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You have no assigned bag sessions.\nOpen a bag from the dashboard to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF718096),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyPatientsState(bool isSearching) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF48BB78).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              AppAssets.patient,
              width: 40,
              height: 40,
              colorFilter: const ColorFilter.mode(
                  Color(0xFF48BB78), BlendMode.srcIn),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'No Results Found' : 'No Patients Registered',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'No patients match your search.\nTry a different name or barcode.'
                : 'No patient samples have been registered\nfor this bag session yet.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF718096),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }


}
