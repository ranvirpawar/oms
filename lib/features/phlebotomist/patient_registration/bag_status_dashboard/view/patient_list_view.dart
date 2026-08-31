import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

import '../../../../../componenents/c_textformfeild.dart';
import '../../../../../constants/app_assets.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../utils/widgets/custom_appbar.dart';
import '../../../../../utils/widgets/modern_dropdown.dart';
import '../controller/patient_list_controller.dart';
import '../model/active_bag_model.dart';

class PatientListPage extends StatelessWidget {
  const PatientListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PatientListController());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: CustomAppBar(
        title: 'Registered Patients',

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
          final index = entry.key + 1;
          final patient = entry.value;
          return _buildPatientCard(patient, index);
        }),
      ],
    );
  }

  // ─── Patient Card ─────────────────────────────────────────────────────────

  Widget _buildPatientCard(PatientRegistrationRecord patient, int index) {
    final hasName = patient.hasPatientName;
    final hasFacility = patient.hasFacility;

    String formattedDate = patient.date;
    try {
      final parsed = DateTime.parse(patient.date);
      formattedDate =
      '${parsed.day.toString().padLeft(2, '0')} ${_monthName(parsed.month)} ${parsed.year}';
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Serial Number
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Patient Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + unidentified badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          hasName
                              ? patient.patientName.trim()
                              : 'Unidentified Patient',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: hasName
                                ? const Color(0xFF2D3748)
                                : const Color(0xFFFC8181),
                          ),
                        ),
                      ),
                      if (!hasName)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                            const Color(0xFFFC8181).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Unknown',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFC8181),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Barcode
                  _buildDetailRow(
                    AppAssets.barcodeIcon,
                    patient.barcode,
                    const Color(0xFF4299E1),
                  ),
                  const SizedBox(height: 6),

                  // Sample type + Date
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailRow(
                          AppAssets.fileNoteIcon,
                          patient.sampleType,
                          const Color(0xFF48BB78),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildDetailRow(
                          AppAssets.calendarIcon,
                          formattedDate,
                          const Color(0xFFED8936),
                        ),
                      ),
                    ],
                  ),

                  // Facility
                  if (hasFacility) ...[
                    const SizedBox(height: 6),
                    _buildDetailRow(
                      AppAssets.facility,
                      patient.facilityName!,
                      const Color(0xFF9F7AEA),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String svgPath, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          svgPath,
          width: 14,
          height: 14,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
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

  String _monthName(int month) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month];
  }
}