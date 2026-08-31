import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_registration/view/widget/dpdp_consent_card.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_registration/view/widget/navigation_buttons_widget.dart';
import 'package:lifenity_connect/features/team_lead/visit_details/view/widgets/custom_dropdown.dart';
import 'package:lifenity_connect/theme/app_colors.dart';
import 'package:lifenity_connect/utils/helper_functions/input_formatter.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';

import '../../../../componenents/c_textformfeild.dart';
import '../../../../componenents/cdateformpicker_field.dart';
import '../../../../constants/app_assets.dart';
import '../../../../constants/app_strings.dart';

import '../../../../utils/widgets/modern_dropdown.dart';
import '../controller/patient_registration_controller.dart';

class PatientRegistrationPage extends StatelessWidget {
  final PatientRegistrationController controller = Get.put(
    PatientRegistrationController(),
  );

  PatientRegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: AppStrings.patientRegistration),
      body: Column(
        children: [
          // Section Navigation
          _buildSectionNavigation(),

          // Form Content
          Expanded(
            child: Obx(() {
              switch (controller.selectedSection.value) {
                case 0:
                  return _buildLabInfoSection();
                case 1:
                  return _buildPatientInfoSection();
                case 2:
                  return _buildResidenceInfoSection();
                /*case 3:
                  return _buildMedicalInfoSection();*/
                default:
                  return _buildLabInfoSection();
              }
            }),
          ),

          // // Navigation Buttons
          NavigationButtons(controller: controller),
        ],
      ),
    );
  }

  Widget _buildSectionNavigation() {
    return SizedBox(
      height: 62,
      // color: Colors.grey.shade100,
      child: Obx(
        () => Row(
          children: List.generate(controller.sections.length, (index) {
            final isSelected = controller.selectedSection.value == index;
            return Expanded(
              child: GestureDetector(
                /*  onTap: () => controller.selectSection(index),*/
                onTap: () {
                  final currentSection = controller.selectedSection.value;

                  // Allow moving backward without validation
                  if (index < currentSection) {
                    controller.selectSection(index);
                    return;
                  }

                  // Moving forward or staying, validate current section first
                  bool isValid = false;

                  switch (currentSection) {
                    case 0:
                      isValid = controller.validateLabInfo();
                      break;
                    case 1:
                      isValid = controller.validatePatientInfo();
                      break;
                    case 2:
                      isValid = controller.validateResidenceInfo();
                      break;
                    default:
                      isValid = true;
                  }

                  if (isValid) {
                    controller.selectSection(index);
                  } else {
                    print('❌ Validation failed. Section change blocked.');
                  }
                },
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    // color: isSelected ? Colors.blue.shade700 : Colors.white,
                    color: isSelected
                        ? Theme.of(Get.context!).colorScheme.primary
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getSectionIcon(index),
                        color: isSelected
                            ? Colors.white
                            : Theme.of(Get.context!).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        controller.sections[index],
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Theme.of(Get.context!).colorScheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  IconData _getSectionIcon(int index) {
    switch (index) {
      case 0:
        return Icons.science;
      case 1:
        return Icons.person_2_rounded;
      case 2:
        return Icons.home;
      case 3:
        return Icons.medical_services;
      default:
        return Icons.question_mark;
    }
  }

  Widget _buildLabInfoSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.labInformation,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Lab Name Dropdown
          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ModernDropdown(
                  label: AppStrings.labName,
                  value: controller.selectedLabName.value?.centerName ?? ' ',
                  /* ? " "
                      : controller.selectedLabName.value!.centerName,*/
                  items: controller.labNames.map((e) => e.centerName).toList(),
                  onChanged: (value) {
                    final selectedLab = controller.labNames.firstWhere(
                      (lab) => lab.centerName == value,
                      orElse: () =>
                          controller.labNames.first, // Fallback (optional)
                    );
                    // debug print
                    debugPrint(
                      'Selected Lab: ${selectedLab.centerName}, code: ${selectedLab.centerId}',
                    );
                    controller.selectedLabName.value =
                        selectedLab; // Update with full CenterModel
                  },
                  iconPath: AppAssets.laboratory,
                  // Replace with lab icon
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
          ModernDropdown(
            isRequired: false,
            iconPath: AppAssets.facility,
            label: 'Ward',
            value: controller.selectedWard.value,
            items: controller.wards,
            onChanged: (value) {
              controller.selectedWard.value = value!;

              controller.selectedFacilityName.value = controller.facilityNames
                  .firstWhere(
                    (facility) => facility.ward == value,
                    orElse: () => controller.facilityNames.first,
                  );
              controller.opdNoController.text = '';
              controller.isOpdVerified.value = false;
              debugPrint(
                'Selected Facility🕵️ ${controller.selectedFacilityName.value?.facilityId} ',
              );
              // reset facility
            },
          ),

          const SizedBox(height: 16),
          // Facility Name Dropdown
          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomDropdown(
                  label: AppStrings.facilityName,
                  value:
                      controller.selectedFacilityName.value?.facilityName ?? '',
                  items: controller.facilityNames
                      .where(
                        (facility) =>
                            facility.ward == controller.selectedWard.value,
                      )
                      .map((e) => e.facilityName)
                      .toList(),
                  onChanged: (value) {
                    if (value != null && value.isNotEmpty) {
                      final selectedFacility = controller.facilityNames
                          .firstWhere(
                            (facility) => facility.facilityName == value,
                          );
                      controller.selectedFacilityName.value = selectedFacility;
                      controller.opdNoController.text = '';
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

          // Process Lab Dropdown
          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ModernDropdown(
                  label: AppStrings.processLab,
                  value: controller.selectedProcessLab.value.isEmpty
                      ? ''
                      : controller.selectedProcessLab.value,
                  items: controller.labNames.map((e) => e.centerName).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectedProcessLab.value = value;
                    }
                  },
                  iconPath: AppAssets.microscope,
                  // Replace with process icon
                  isRequired: true,
                ),
                if (controller.labInfoError.value.isNotEmpty &&
                    controller.selectedProcessLab.value.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 4.0, left: 8.0),
                    child: Text(
                      'Please select process lab',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sample Type Dropdown
          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ModernDropdown(
                  label: AppStrings.sampleType,
                  value: controller.selectedSampleType.value.isEmpty
                      ? ' '
                      : controller.selectedSampleType.value,
                  items: controller.sampleTypes,
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectedSampleType.value = value;
                    }
                  },
                  iconPath: AppAssets.testTube,
                  // Replace with sample icon
                  isRequired: true,
                ),
                if (controller.labInfoError.value.isNotEmpty &&
                    controller.selectedSampleType.value.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 4.0, left: 8.0),
                    child: Text(
                      'Please select sample type',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Patient Type Dropdown
          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ModernDropdown(
                  label: AppStrings.patientType,
                  value: controller.selectedPatientType.value.isEmpty
                      ? ' '
                      : controller.selectedPatientType.value,
                  items: controller.patientTypes,
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectedPatientType.value = value;
                    }
                  },
                  iconPath: AppAssets.patient,
                  // Replace with patient icon
                  isRequired: true,
                ),
                if (controller.labInfoError.value.isNotEmpty &&
                    controller.selectedPatientType.value.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 4.0, left: 8.0),
                    child: Text(
                      'Please select patient type',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // OPD Number Text Field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Obx(() {
                return CFormTextField(
                  controller: controller.opdNoController,
                  label: '${controller.selectedPatientType.value} Number',
                  iconPath: AppAssets.healthReportSvg,
                  keyboardType: TextInputType.number,
                  inputFormatters: InputFormatters.digits,
                  isRequired: true,
                  onChanged: controller.onOpdNumberChanged,
                  suffix: _buildSuffixIconOPD(controller),
                );
              }),
              Obx(() {
                if (controller.labInfoError.value.isNotEmpty &&
                    controller.opdNoController.text.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 4.0, left: 8.0),
                    child: Text(
                      'Please enter OPD number',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),

          // General Error Message
          Obx(() {
            if (controller.labInfoError.value.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          controller.labInfoError.value,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildPatientInfoSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.patientInformation,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Patient Type Selection
          Obx(
            () => Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.togglePatientType(true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: controller.isNewPatient.value
                              ? Theme.of(Get.context!).colorScheme.primary
                              : Colors.transparent,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          AppStrings.newPatient,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: controller.isNewPatient.value
                                ? Colors.white
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.togglePatientType(false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !controller.isNewPatient.value
                              ? Theme.of(Get.context!).colorScheme.primary
                              : Colors.transparent,
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          AppStrings.existingPatient,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !controller.isNewPatient.value
                                ? Colors.white
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Obx(() {
            if (!controller.isNewPatient.value) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    AppStrings.searchExistingPatient,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),

                  // System Type Selector (HMIS/NHM)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSystemTab(
                            label: 'Regular', // regular equal to nhm
                            isSelected:
                                controller.selectedSystemType.value == 'NHM',
                            onTap: () => controller.changeSystemType('NHM'),
                            systemType: 'NHM',
                          ),
                        ),
                        Expanded(
                          child: _buildSystemTab(
                            label: 'HMIS',
                            isSelected:
                                controller.selectedSystemType.value == 'HMIS',
                            onTap: () => controller.changeSystemType('HMIS'),
                            systemType: 'HMIS',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Search Type Options (Compact Row)
                  const Text(
                    'Search By',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Compact Radio Button Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildCompactSearchOption(
                          title: 'Mobile',
                          value: 'mobile',
                          groupValue: controller.selectedSearchIdType.value,
                          onChanged: (value) =>
                              controller.changeSearchType(value!),
                          systemType: controller.selectedSystemType.value,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildCompactSearchOption(
                          title: 'OPD',
                          value: 'opd',
                          groupValue: controller.selectedSearchIdType.value,
                          onChanged: (value) =>
                              controller.changeSearchType(value!),
                          systemType: controller.selectedSystemType.value,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildCompactSearchOption(
                          title: 'Patient ID',
                          value: 'patient_id',
                          groupValue: controller.selectedSearchIdType.value,
                          onChanged: (value) =>
                              controller.changeSearchType(value!),
                          systemType: controller.selectedSystemType.value,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Search Input Field
                  CFormTextField(
                    controller: controller.searchIdNumberController,
                    label:
                        'Enter ${_getSearchLabel(controller.selectedSearchIdType.value)}',
                    iconPath: AppAssets.idProofIcon,
                    inputFormatters:
                        controller.selectedSearchIdType.value == 'mobile'
                        ? [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ]
                        : [],
                    isRequired: true,
                    iconColor: controller.selectedSystemType.value == 'HMIS'
                        ? AppColors.hmisPrimary
                        : null,
                    backgroundColor:
                        controller.selectedSystemType.value == 'HMIS'
                        ? AppColors.hmisPrimary.withOpacity(0.05)
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Search Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.isSearchingPatient.value
                          ? null
                          : controller.searchExistingPatient,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            controller.selectedSystemType.value == 'HMIS'
                            ? AppColors.hmisPrimary
                            : Theme.of((Get.context!)).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: controller.isSearchingPatient.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              AppStrings.search,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  // Search Error
                  if (controller.searchError.value.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                controller.searchError.value,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                ],
              );
            }
            return const SizedBox.shrink();
          }),

          // Patient Details Form
          const Text(
            AppStrings.patientDetails,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),

          // Prefix Dropdown
          Obx(
            () => ModernDropdown(
              label: AppStrings.prefix,
              value: controller.selectedPrefix.value.isEmpty
                  ? ' '
                  : controller.selectedPrefix.value,
              items: controller.prefixes,
              onChanged: (value) {
                if (value != null) {
                  controller.selectedPrefix.value = value;
                }
              },
              iconPath: AppAssets.patient,
              isRequired: true,
            ),
          ),
          const SizedBox(height: 16),

          // Name Fields Row
          Row(
            children: [
              Expanded(
                child: CFormTextField(
                  controller: controller.firstNameController,
                  label: AppStrings.firstName,
                  iconPath: AppAssets.patient,
                  isRequired: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z ]+$')),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CFormTextField(
                  controller: controller.middleNameController,
                  label: AppStrings.middleName,
                  iconPath: AppAssets.patient,
                  isRequired: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z ]+$')),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          CFormTextField(
            controller: controller.lastNameController,
            label: AppStrings.lastName,
            iconPath: AppAssets.patient,
            isRequired: true,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z ]+$')),
            ],
          ),
          const SizedBox(height: 16),
          Obx(
            () => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CFormTextField(
                  controller: controller.mobileNumberController,
                  label: 'Mobile',
                  iconPath: AppAssets.userIcon,
                  keyboardType: TextInputType.phone,
                  inputFormatters: InputFormatters.digits,
                  maxLength: 10,
                  isRequired: true,
                  isReadOnly: controller.isVerified.value,
                  onChanged: (value) {
                    if (value.length == 10) {
                      controller.validateMobileNumber();
                    }
                  },
                  suffix: _buildSuffixIcon(controller),
                ),
                if (controller.mobileNumberError.value.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, left: 8.0),
                    child: Text(
                      controller.mobileNumberError.value,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          /*const SizedBox(height: 16),
          Obx(() {
            if (!controller.showConsentSection.value) return const SizedBox.shrink();
            return _buildDpdpConsentCard(controller);
          }),*/
          const SizedBox(height: 16),

          // Gender Dropdown
          Obx(
            () => ModernDropdown(
              label: AppStrings.gender,
              value: controller.selectedGender.value.isEmpty
                  ? ' '
                  : controller.selectedGender.value,
              items: controller.genders,
              onChanged: (value) {
                if (value != null) {
                  controller.selectedGender.value = value;
                }
              },
              iconPath: AppAssets.patient,
              isRequired: true,
            ),
          ),

          Obx(() {
            if (controller.selectedGender.value == 'Female') {
              return Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ModernDropdown(
                  label: AppStrings.anc,
                  value: controller.selectedANCList.value.isEmpty
                      ? ' '
                      : controller.selectedANCList.value,
                  items: controller.ancList,
                  onChanged: (value) {
                    if (value != null) {
                      controller.selectedANCList.value = value;
                    }
                  },
                  iconPath: AppAssets.patient,
                  isRequired: true,
                ),
              );
            } else {
              return const SizedBox.shrink();
            }
          }),
          const SizedBox(height: 16),

          // Date of Birth and Age Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Obx(
                  () => CFormDateField(
                    label: AppStrings.dateOfBirth,
                    value: controller.selectedDateOfBirth.value != null
                        ? '${controller.selectedDateOfBirth.value!.day}/${controller.selectedDateOfBirth.value!.month}/${controller.selectedDateOfBirth.value!.year}'
                        : '',
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: Get.context!,
                        initialDate:
                            controller.selectedDateOfBirth.value ??
                            DateTime.now(),
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now(),
                        initialEntryMode: DatePickerEntryMode.calendarOnly,
                      );
                      if (picked != null) {
                        controller.selectedDateOfBirth.value = picked;
                      }
                    },
                    iconPath: AppAssets.calendarIcon,
                    isRequired: false,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Obx(
                  () => CFormTextField(
                    controller: controller.ageController,
                    label: AppStrings.age,
                    iconPath: AppAssets.patient,
                    maxLength: 3,
                    isReadOnly: controller.selectedDateOfBirth.value != null,
                    keyboardType: TextInputType.phone,
                    inputFormatters: InputFormatters.digits,
                    isTextSuffix: true,
                    suffix: controller.selectedPrefix.value == 'Baby'
                        ? SizedBox(
                            width: 80,
                            child: controller.selectedDateOfBirth.value != null
                                ? // Show static text when DOB is selected
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      controller.getAgeTitle(),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey, // Show as disabled
                                      ),
                                    ),
                                  )
                                : // Show dropdown when DOB is not selected
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: controller.selectedAgeTitle.value,
                                      isDense: true,
                                      iconSize: 18,
                                      items: controller.ageTitleOptions.map((
                                        String value,
                                      ) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(
                                            value,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                        if (newValue != null) {
                                          controller.selectedAgeTitle.value =
                                              newValue;
                                          // Clear age when switching between Days/Years
                                          controller.ageController.clear();
                                        }
                                      },
                                    ),
                                  ),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              controller.getAgeTitle(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          Obx(() {
            if (controller.ageValidation.value.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          controller.ageValidation.value,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          const SizedBox(height: 16),

          // Marital Status Dropdown
          Obx(
            () => ModernDropdown(
              label: AppStrings.maritalStatus,
              value: controller.selectedMaritalStatus.value.isEmpty
                  ? ''
                  : controller.selectedMaritalStatus.value,
              items: controller.maritalStatuses
                  .map((e) => e.maritalStatus)
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  controller.selectedMaritalStatus.value = value;
                }
              },
              iconPath: AppAssets.patient,
              isRequired: true,
            ),
          ),
          const SizedBox(height: 16),

          // ID Type Dropdown
          Obx(
            () => ModernDropdown(
              label: AppStrings.idProofType,
              value: controller.selectedIdType.value.isEmpty
                  ? ' '
                  : controller.selectedIdType.value,
              items: controller.idProofTypes.map((e) => e.idTypeName).toList(),
              onChanged: (value) {
                if (value != null) {
                  controller.selectedIdType.value = value;
                }
              },
              iconPath: AppAssets.idProofIcon,
              isRequired: false,
            ),
          ),
          const SizedBox(height: 16),

          // ID Proof Number
          CFormTextField(
            controller: controller.idProofNumberController,
            label: AppStrings.idProofNumber,
            iconPath: AppAssets.idProofIcon,
            isRequired: false,
            inputFormatters: [
              if (controller.selectedIdType.value.toLowerCase() ==
                  'aadhaar card')
                FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
              if (controller.selectedIdType.value.toLowerCase() ==
                  'driving licence')
                FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
              LengthLimitingTextInputFormatter(12),
            ],
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (!controller.showConsentSection.value) {
              return const SizedBox.shrink();
            }
            return DpdpConsentCard(controller: controller);
          }),

          // Patient Info Error
          Obx(() {
            if (controller.patientInfoError.value.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          controller.patientInfoError.value,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget _buildResidenceInfoSection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.residenceInformation,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Address
          CFormTextField(
            controller: controller.addressController,
            label: AppStrings.address,
            iconPath: AppAssets.mapPinIcon,
            // Replace with address icon
            isRequired: true,
            maxLines: 1,
          ),
          const SizedBox(height: 16),

          // Pincode
          CFormTextField(
            controller: controller.pincodeController,
            label: AppStrings.pincode,
            iconPath: AppAssets.mapPinIcon,
            // Replace with location icon
            isRequired: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
          ),

          const SizedBox(height: 16),

          // Residence Info Error
          Obx(() {
            if (controller.residenceInfoError.value.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          controller.residenceInfoError.value,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }

  Widget buildCompactReferencesRow(VoidCallback onAddDoctor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          AppStrings.references,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: 0.2,
          ),
        ),
        GestureDetector(
          onTap: onAddDoctor,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary900, AppColors.primary700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade200.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_circle_outline, size: 18, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  AppStrings.addDoctor,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuffixIcon(PatientRegistrationController controller) {
    return Obx(
      () => controller.isMobileVerified.value
          ? const Icon(Icons.check_circle, color: Colors.green)
          : controller.isMobileVerifying.value
          ? const CircularProgressIndicator()
          : const SizedBox.shrink(),
    );
  }

  Widget _buildSuffixIconOPD(PatientRegistrationController controller) {
    return Obx(
      () => controller.isOpdVerified.value
          ? const Icon(Icons.check_circle, color: Colors.green)
          : controller.isOPDVerifying.value
          ? const CircularProgressIndicator()
          : const SizedBox.shrink(),
    );
  }

  Widget _buildSystemTab({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required String systemType,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (systemType == 'HMIS'
                    ? AppColors.hmisPrimary
                    : Theme.of(Get.context!).primaryColor)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSearchOption({
    required String title,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
    required String systemType,
  }) {
    final isSelected = value == groupValue;

    // Determine color based on system type
    final activeColor = systemType == 'HMIS'
        ? AppColors.hmisPrimary
        : Theme.of((Get.context!)).primaryColor;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.1)
              : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? activeColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? activeColor : Colors.black54,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getSearchLabel(String searchType) {
    switch (searchType) {
      case 'mobile':
        return 'Mobile Number';
      case 'opd':
        return 'OPD Number';
      case 'patient_id':
        return 'Patient ID';
      default:
        return 'ID Number';
    }
  }

  Widget _buildDpdpConsentCard(PatientRegistrationController controller) {
    return Obx(() {
      if (controller.isCheckingConsent.value) {
        return _consentStatusContainer(
          color: Colors.blue,
          icon: Icons.hourglass_top,
          child: const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text('Checking DPDP consent status...'),
            ],
          ),
        );
      }

      if (controller.isConsentVerified.value) {
        return _consentStatusContainer(
          color: Colors.green,
          icon: Icons.verified_user,
          child: Text(
            controller.consentStatusMessage.value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        );
      }

      // Link sent, waiting for patient to confirm on their own phone
      if (controller.isConsentLinkSent.value) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.mark_email_read_outlined,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Verification link sent',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (controller.isPollingConsent.value)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Sent to ${controller.mobileNumberController.text}. Waiting for '
                'the patient to confirm consent on their phone — this will '
                'update automatically.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: controller.isCheckingConsent.value
                          ? null
                          : controller.checkConsentStatusNow,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text(
                        'Check Status',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: controller.consentResendSeconds.value == 0
                          ? controller.resendConsentLink
                          : null,
                      child: Text(
                        controller.consentResendSeconds.value == 0
                            ? 'Resend Link'
                            : 'Resend in ${controller.consentResendSeconds.value}s',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: controller.isUploadingConsentPhoto.value
                      ? null
                      : () => _showConsentSourceSheet(controller),
                  icon: const Icon(Icons.camera_alt_outlined, size: 16),
                  label: const Text(
                    'No response? Capture paper consent instead',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      // Not verified, link not yet sent — offer both paths
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.privacy_tip_outlined,
                  color: Colors.orange.shade800,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'DPDP consent required before you can proceed',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.isSendingConsentLink.value
                        ? null
                        : controller.sendConsentLink,
                    icon: controller.isSendingConsentLink.value
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.link, size: 16),
                    label: const Text(
                      'Send Verification Link',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.isUploadingConsentPhoto.value
                        ? null
                        : () => _showConsentSourceSheet(controller),
                    icon: controller.isUploadingConsentPhoto.value
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt_outlined, size: 16),
                    label: const Text(
                      'Paper Consent',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            if (controller.consentLinkError.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  controller.consentLinkError.value,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            if (controller.consentError.value.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  controller.consentError.value,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      );
    });
  }

  void _showConsentSourceSheet(PatientRegistrationController controller) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Capture Paper Consent',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Use this if the patient does not have a working mobile number',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Get.back();
                controller.pickConsentPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Get.back();
                controller.pickConsentPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _consentStatusContainer({
    required Color color,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: child),
        ],
      ),
    );
  }
}
