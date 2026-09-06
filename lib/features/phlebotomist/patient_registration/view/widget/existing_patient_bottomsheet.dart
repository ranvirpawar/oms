import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../../../constants/app_assets.dart';
import '../../../../../constants/app_strings.dart';
import '../../../../../theme/app_colors.dart';
import '../../models/existing_patient_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

// Assuming these are already defined in your project:
// AppColors, AppStrings, AppAssets, ExistingPatientModel

class PatientSelectionSheet extends StatefulWidget {
  final List<ExistingPatientModel> patients;
  final Function(ExistingPatientModel) onPatientSelected;

  const PatientSelectionSheet({
    super.key,
    required this.patients,
    required this.onPatientSelected,
  });

  @override
  State<PatientSelectionSheet> createState() => _PatientSelectionSheetState();

  // Static method to show the bottom sheet
  static void show(
      List<ExistingPatientModel> patients,
      Function(ExistingPatientModel) onPatientSelected,
      ) {
    Get.bottomSheet(
      PatientSelectionSheet(
        patients: patients,
        onPatientSelected: onPatientSelected,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }
}

class _PatientSelectionSheetState extends State<PatientSelectionSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<ExistingPatientModel> _filteredPatients = [];

  @override
  void initState() {
    super.initState();
    _filteredPatients = List.from(widget.patients); // Copy the list
    _searchController.addListener(_filterPatients);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterPatients() {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _filteredPatients = List.from(widget.patients);
      });
      return;
    }

    setState(() {
      _filteredPatients = widget.patients.where((patient) {
        final fullName = _getFullName(patient).toLowerCase();
        final details = _getPatientDetails(patient).toLowerCase();
        return fullName.contains(query) || details.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: Get.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  AppStrings.selectPatient,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.primary),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or details...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () => _searchController.clear(),
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),

          // Patient List
          Expanded(
            child: _filteredPatients.isEmpty
                ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'No patients found',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredPatients.length,
              itemBuilder: (context, index) {
                final patient = _filteredPatients[index];
                return _buildModernPatientTile(context, patient);
              },
            ),
          ),

          // Bottom padding
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildModernPatientTile(BuildContext context, ExistingPatientModel patient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Get.back();
            widget.onPatientSelected(patient);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                SvgPicture.asset(
                  AppAssets.patient,
                  color: AppColors.primary,
                  height: 24,
                ),
                const SizedBox(width: 12),

                // Patient Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getFullName(patient),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getPatientDetails(patient),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Chevron
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getFullName(ExistingPatientModel patient) {
    final List<String> nameParts = [];

    if (patient.title.isNotEmpty) nameParts.add(patient.title.trim());
    if (patient.firstName.isNotEmpty) nameParts.add(patient.firstName);
    if (patient.middleName.isNotEmpty) nameParts.add(patient.middleName);
    if (patient.lastName.isNotEmpty) nameParts.add(patient.lastName);

    return nameParts.join(' ');
  }

  String _getPatientDetails(ExistingPatientModel patient) {
    final List<String> details = [];

    if (patient.gender.isNotEmpty) {
      details.add(patient.gender);
    }

    if (patient.age.isNotEmpty) {
      String ageText = patient.age;
      if (patient.ageTitle.isNotEmpty) {
        ageText += ' ${patient.ageTitle.toLowerCase()}';
      }
      details.add(ageText);
    }

    return details.join(' • ');
  }
}

/*
class PatientSelectionSheet extends StatelessWidget {
  final List<ExistingPatientModel> patients;
  final Function(ExistingPatientModel) onPatientSelected;

  const PatientSelectionSheet({
    super.key,
    required this.patients,
    required this.onPatientSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: Get.height * 0.5,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with close button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Select Patient",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.primary),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
          ),
          // Patient list
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: patients.length,
              itemBuilder: (context, index) {
                final patient = patients[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1), // Primary color with opacity
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: SvgPicture.asset(
                      AppAssets.patient, // SVG icon from AppAssets
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).primaryColor,
                        BlendMode.srcIn,
                      ),
                    ),
                    title: Text(
                      '${patient.firstName} ${patient.lastName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '${patient.mobileNumber} • ${patient.address}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    onTap: () {
                      Get.back(); // Close bottom sheet
                      onPatientSelected(patient);
                    },
                  ),
                );
              },
            ),
          ),
          // Bottom padding
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  static void show(List<ExistingPatientModel> patients, Function(ExistingPatientModel) onPatientSelected) {
    Get.bottomSheet(
      PatientSelectionSheet(
        patients: patients,
        onPatientSelected: onPatientSelected,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
  }
}*/
