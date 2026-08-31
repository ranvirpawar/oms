// Test Barcode View

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lifenity_connect/componenents/c_textformfeild.dart';
import 'package:lifenity_connect/componenents/cdateformpicker_field.dart';
import 'package:lifenity_connect/constants/app_assets.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_registration/view/widget/add_doctor_button.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_registration/view/widget/patient_card_header.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_registration/view/widget/trf_upload_widget.dart';

import 'package:lifenity_connect/services/snackbar_service.dart';
import 'package:lifenity_connect/utils/helper_functions/helper_methods.dart';
import 'package:lifenity_connect/utils/widgets/custom_appbar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../componenents/success_dialog.dart';
import '../../../../constants/app_strings.dart';
import '../../../../utils/widgets/modern_dropdown.dart';
import '../bag_status_dashboard/controller/registrarion_bag_controller.dart';
import '../controller/sample_collection_controller.dart';
import '../models/tests_model.dart';

class TestBarcodeView extends StatelessWidget {
  final List<TestModel> selectedTests;
  final String bagId;

  final Map<String, dynamic> patientArray;
  final TestBarcodeController controller = Get.put(TestBarcodeController());
  final String? requisitionDno;
  final String? hmisVoucherNumber; // ← ne

  TestBarcodeView({
    super.key,
    required this.selectedTests,
    required this.patientArray,
    required this.bagId,
    this.requisitionDno,
    this.hmisVoucherNumber,
  });

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.bagId.value = bagId;
      controller.initializeWithSelectedTests(
        selectedTests,
        patientArray,
        requisitionDno,
        hmisVoucherNumber,
      );
    });

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Sample Collection',
        actions: [
          AddDoctorButton(onAddDoctor: () => controller.addNewDoctor()),
        ],
      ),
      body: Obx(() {
        return RefreshIndicator(
          onRefresh: () async {
            controller.fetchDoctorReferences();
          },
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.translucent,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Patient Name
                  PatientCardHeader(
                    firstName: controller.patientFirstName.value,
                    lastName: controller.patientLastName.value,
                    patientId: patientArray['patientArray']?[0]?['patientId']
                        ?.toString(),
                    phoneNumber:
                        patientArray['patientArray']?[0]?['phoneNumber']
                            ?.toString(),
                    age: patientArray['patientArray']?[0]?['age']?.toString(),
                    gender: patientArray['patientArray']?[0]?['gender']
                        ?.toString(),
                    facilityName:
                        patientArray['patientArray']?[0]?['facilityName']
                            ?.toString(),
                    testCount: controller.selectedTests.length,
                    onEditPressed: () {
                      // Handle edit patient action if needed
                    },
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CFormDateField(
                          label: 'Collection Date',
                          value: DateFormat(
                            'dd/MM/yyyy',
                          ).format(DateTime.now()),
                          onTap: () {},
                          iconPath: AppAssets.calendarIcon,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: CFormDateField(
                          iconPath: AppAssets.calendarClockIcon,
                          label: 'Collection Time',
                          isReadOnly: true,
                          onTap: () async {},
                          value: controller.selectedTime.value.format(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildBarcodeFields(context),

                  // receipt number feild
                  if (controller.hasHmisTests.value)
                    CFormTextField(
                      label: 'Receipt Number  ',
                      iconPath: AppAssets.fileNoteIcon,
                      isRequired: false,
                      controller: controller.hmisVoucherController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9 -]'),
                        ),
                      ],
                    ),

                  if (controller.hasHmisTests.value) const SizedBox(height: 16),
                  if (controller.hasBasicTests.value)
                    CFormTextField(
                      label: 'Basic Receipt Number',
                      iconPath: AppAssets.fileNoteIcon,
                      isRequired: false,
                      controller: controller.basicReceiptNumberController,
                      inputFormatters: [
                        // alphanumeric with space also allow -
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9 -]'),
                        ),
                      ],
                    ),

                  if (controller.hasBasicTests.value)
                    const SizedBox(height: 16),

                  if (controller.hasAdvancedTests.value)
                    CFormTextField(
                      label: 'Advanced Receipt Number',
                      iconPath: AppAssets.fileNoteIcon,
                      isRequired: false,
                      controller: controller.advancedReceiptNumberController,
                      inputFormatters: [
                        // alphanumeric with space also allow -
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[a-zA-Z0-9 -]'),
                        ),
                      ],
                    ),
                  if (controller.hasAdvancedTests.value)
                    const SizedBox(height: 16),

                  Obx(
                    () => ModernDropdown(
                      iconPath: AppAssets.doctor,
                      label: AppStrings.doctorName,
                      value:
                          controller.selectedDoctor.value?.refDoctorName ?? '',
                      items: controller.doctorNames
                          .map((e) => e.refDoctorName ?? '')
                          .toList(),
                      onChanged: (selectedName) {
                        final selected = controller.doctorNames
                            .firstWhereOrNull(
                              (doc) => doc.refDoctorName == selectedName,
                            );
                        controller.selectedDoctor.value = selected;
                      },
                    ),
                  ),
                  /* const SizedBox(height: 12),
                  // Doctor References Section
                  AddDoctorButton(onAddDoctor: () => controller.addNewDoctor()),*/
                  const SizedBox(height: 16),
                  _BagCapacityWarning(bagId: bagId),
                  const SizedBox(height: 8),
                  _buildSelectedTestsTable(context),
                  const SizedBox(height: 24),
                  _buildTubeRequirementsTable(context),
                  const SizedBox(height: 24),

                  // TRF Upload Section
                  TrfUploadWidget(
                    selectedFiles: controller.selectedTrfFiles,
                    onAddFiles: () => controller.showImageSourceSelection(),
                    onRemoveFile: (index) => controller.removeTrfFile(index),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: Obx(
                      () => FloatingActionButton.extended(
                        onPressed: controller.isProcessing.value
                            ? null
                            : () => _processAndContinue(context),
                        backgroundColor: Theme.of(context).primaryColor,
                        label: controller.isProcessing.value
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                'Save',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // Updated build method for the barcode fields in TestBarcodeView
  Widget _buildBarcodeFields(BuildContext context) {
    return Column(
      children: [
        // Main Barcode Field
        Obx(() {
          if (!controller.shouldShowMainBarcode()) {
            return const SizedBox.shrink();
          }
          return Column(
            children: [
              CFormTextField(
                controller: controller.mainBarcodeController,
                label: controller.getMainBarcodeLabel(),
                iconPath: AppAssets.barcodeIcon,
                isRequired: true,
                keyboardType: TextInputType.number,
                maxLength: 14,
                suffix: controller.buildSuffixIcon(isMainBarcode: true),
                onChanged: (value) {
                  // The listener will handle the validation
                },
              ),
              Obx(() {
                if (controller.isMainBarcodeChecking.value) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Validating barcode...',
                          style: TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              Obx(() {
                if (controller.mainBarcodeError.value.isNotEmpty) {
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
                              controller.mainBarcodeError.value,
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
            ],
          );
        }),

        // Sugar Barcode Field (conditional)
        Obx(() {
          if (!controller.shouldShowGlucoseBarcode()) {
            return const SizedBox.shrink();
          }
          return Column(
            children: [
              CFormTextField(
                controller: controller.glucoseBarcodeController,
                label: 'Glucose Barcode',
                iconPath: AppAssets.barcodeIcon,
                isRequired: true,
                keyboardType: TextInputType.number,
                maxLength: 14,
                suffix: controller.buildSuffixIcon(isMainBarcode: false),
                onChanged: (value) {
                  // The listener will handle the validation
                },
              ),
              Obx(() {
                if (controller.isGlucoseBarcodeChecking.value) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Validating barcode...',
                          style: TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              Obx(() {
                if (controller.glucoseBarcodeError.value.isNotEmpty) {
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
                              controller.glucoseBarcodeError.value,
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
            ],
          );
        }),
      ],
    );
  }

  Widget _buildSelectedTestsTable(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(3),
            2: FlexColumnWidth(2),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              children: const [
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'S.No',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Test Name',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Tube Required',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ...controller.selectedTests.asMap().entries.map((entry) {
              final index = entry.key;
              final test = entry.value;
              final isEven = index % 2 == 0;

              return TableRow(
                decoration: BoxDecoration(
                  color: isEven ? Colors.grey[50] : Colors.white,
                ),
                children: [
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        '${index + 1}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            test.testName ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (test.testCode?.isNotEmpty == true)
                            Text(
                              'Code: ${test.testCode}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          test.tubeContent ?? 'N/A',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTubeRequirementsTable(BuildContext context) {
    // Ensure TRF is present in the controller with default values
    if (!controller.tubeRequirements.containsKey('TRF')) {
      controller.tubeRequirements['TRF'] = {
        'testCount': 0,
        'requiredQuantity': 1.obs,
        'tubeId': 100,
      }.obs;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(3.5),
          },
          children: [
            // Header row
            TableRow(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              children: const [
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'S.No',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Tube Type',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Tests',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                TableCell(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Tube Required',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),

            // Dynamic rows
            ...controller.tubeRequirements.entries.toList().asMap().entries.map((
              entry,
            ) {
              final index = entry.key;
              final tubeEntry = entry.value;
              final tubeType = tubeEntry.key;
              final tubeId = tubeEntry.value['tubeId'];
              final tubeData = tubeEntry.value;
              final isEven = index % 2 == 0;

              return TableRow(
                decoration: BoxDecoration(
                  color: isEven ? Colors.grey[100] : Colors.white,
                ),
                children: [
                  // S.No
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        '${index + 1}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),

                  // Tube Type
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        tubeType,
                        /*  "${tubeType} $tubeId",*/
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),

                  // Test Count
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${tubeData['testCount']}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Quantity Selector
                  TableCell(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Obx(() {
                        final quantity = tubeData['requiredQuantity'].value;
                        final qtyController = TextEditingController(
                          text: quantity.toString(),
                        );

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Decrement Button
                            IconButton(
                              onPressed: () {
                                if (quantity > 1) {
                                  controller.updateTubeQuantity(
                                    tubeType,
                                    quantity - 1,
                                  );
                                }
                              },
                              icon: Icon(
                                Icons.remove_circle,
                                color: Theme.of(context).primaryColor,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                              padding: EdgeInsets.zero,
                            ),

                            // Quantity Field
                            SizedBox(
                              width: 40,
                              child: TextField(
                                controller: qtyController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).primaryColor,
                                ),
                                onSubmitted: (value) {
                                  final newQty = int.tryParse(value);
                                  if (newQty != null &&
                                      newQty >= 1 &&
                                      newQty <= 3) {
                                    controller.updateTubeQuantity(
                                      tubeType,
                                      newQty,
                                    );
                                  } else {
                                    // reset to last valid value if out of range
                                    qtyController.text = quantity.toString();
                                  }
                                },
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),

                            // Increment Button
                            IconButton(
                              onPressed: () {
                                if (quantity < 3) {
                                  controller.updateTubeQuantity(
                                    tubeType,
                                    quantity + 1,
                                  );
                                }
                              },
                              icon: Icon(
                                Icons.add_circle,
                                color: Theme.of(context).primaryColor,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  void _processAndContinue(BuildContext context) async {
    if (controller.shouldShowMainBarcode() &&
        (controller.mainBarcodeController.text.isEmpty ||
            controller.mainBarcodeError.value.isNotEmpty)) {
      SnackBarService.to.showMessage(message: 'Please enter a valid barcode');
      return;
    }

    if (controller.shouldShowGlucoseBarcode() &&
        (controller.glucoseBarcodeController.text.isEmpty ||
            controller.glucoseBarcodeError.value.isNotEmpty)) {
      SnackBarService.to.showMessage(
        message: 'Please enter a valid glucose barcode',
      );
      return;
    }

    // Validate selected doctor
    if (controller.selectedDoctor.value == null) {
      SnackBarService.to.showMessage(message: 'Please select the doctor');
      return;
    }
    // both receipt number should not be identical
    if (controller.basicReceiptNumberController.text.isNotEmpty &&
        controller.advancedReceiptNumberController.text.isNotEmpty &&
        controller.basicReceiptNumberController.text ==
            controller.advancedReceiptNumberController.text) {
      SnackBarService.to.showMessage(
        message: 'Basic & Advanced receipt numbers should not be identical',
      );
      return;
    }
    // making trf upload compulsory
    if (controller.selectedTrfFiles.isEmpty) {
      SnackBarService.to.showMessage(message: 'It is mandatory to upload trf files');
      return;
    }

    try {


      controller.isProcessing.value = true;
      // 1. register the patient first
      final patientResponse = await controller.patientRegistrationService
          .savePatientDetails(patientArray);
      final patientPermanentId = patientResponse['patientPermid'];
      HelperMethods.printDebug('🔄 Patient Permanent ID: $patientPermanentId');

      // 2. Submit lab data first
      final apiBody = controller.getLabTestMasterArray(
        patientArray,
        patientPermanentId,
      );
      HelperMethods.printDebug('🔄 Generated API Body: $apiBody');

      final response = await controller.patientRegistrationService
          .submitLabData(apiBody);
      HelperMethods.printDebug('✅ API Response: ');
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(apiBody);
      await prefs.setString('processedData', jsonString);
      // 3. Submit order input
      final orderInput = controller.getOrderInputPayload(patientArray);
      HelperMethods.printDebug('Submitting Order Input: $orderInput');

      await controller.patientRegistrationService.submitOrderInput(orderInput);

      // 4. Upload TRF files if any selected
      if (controller.selectedTrfFiles.isNotEmpty) {
        HelperMethods.printDebug(
          '📤 Uploading ${controller.selectedTrfFiles.length} TRF file(s)...',
        );
        final uploadSuccess = await controller.uploadTrfFiles();

        if (!uploadSuccess) {
          // Show warning but don't block success
          Get.snackbar(
            'Warning',
            'Patient registered successfully but some TRF files failed to upload',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        } else {
          HelperMethods.printDebug('✅ All TRF files uploaded successfully');
        }
      }
      SuccessDialog.show(context);
    } catch (e) {
      String errorMessage = 'Failed to submit lab test data';

      if (e.toString().contains('Details Alredy Exists') ||
          e.toString().contains('Details Already Exists')) {
        errorMessage = 'Patient details already exist in the system';
      } else if (e.toString().contains('Server error')) {
        errorMessage =
            'Server is currently unavailable. Please try again later.';
      } else {
        errorMessage = 'Failed to submit lab test data: ${e.toString()}';
      }

      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      controller.isProcessing.value = false;
    }
  }
}

class _BagCapacityWarning extends StatelessWidget {
  final String bagId;

  const _BagCapacityWarning({required this.bagId});

  @override
  Widget build(BuildContext context) {
    final bagController = Get.find<BagRegistrationController>();

    return Obx(() {
      HelperMethods.printDebug(
        '🛍️ [BagCapacityWarning] build triggered — bagId: "$bagId"',
      );
      HelperMethods.printDebug(
        '🛍️ [BagCapacityWarning] allSessions count: ${bagController.allSessions.length}',
      );
      HelperMethods.printDebug(
        '🛍️ [BagCapacityWarning] allSessions bagIds: ${bagController.allSessions.map((s) => s.bagId.toString()).toList()}',
      );

      final session = bagController.allSessions.firstWhereOrNull(
        (s) => s.bagId.toString() == bagId,
      );

      if (session == null) {
        HelperMethods.printDebug(
          '🛍️ [BagCapacityWarning] ❌ session not found for bagId: "$bagId" — returning shrink',
        );
        return const SizedBox.shrink();
      }
      HelperMethods.printDebug(
        '🛍️ [BagCapacityWarning] ✅ session found: bagId=${session.bagId}, sessionID=${session.sessionID}',
      );

      HelperMethods.printDebug(
        '🛍️ [BagCapacityWarning] bagDetailsMap keys: ${bagController.bagDetailsMap.keys.toList()}',
      );
      final details = bagController.bagDetailsMap[session.bagId];

      if (details == null) {
        HelperMethods.printDebug(
          '🛍️ [BagCapacityWarning] ❌ details not found for bagId: ${session.bagId} — returning shrink',
        );
        HelperMethods.printDebug(
          '🛍️ [BagCapacityWarning] 💡 Tip: ensureBagDetailsLoaded() may not have been called yet',
        );
        return const SizedBox.shrink();
      }
      HelperMethods.printDebug(
        '🛍️ [BagCapacityWarning] ✅ details found — capacity: ${details.capacity}, patientCount: ${details.patientCount}',
      );

      final capacity = details.capacity;
      if (capacity <= 0) {
        HelperMethods.printDebug(
          '🛍️ [BagCapacityWarning] ❌ capacity is $capacity (≤ 0) — returning shrink',
        );
        return const SizedBox.shrink();
      }

      final used = details.patientCount;
      final pct = used / capacity;
      HelperMethods.printDebug(
        '🛍️ [BagCapacityWarning] 📊 used=$used, capacity=$capacity, pct=${(pct * 100).toStringAsFixed(1)}%',
      );

      if (pct < 0.9) {
        HelperMethods.printDebug(
          '🛍️ [BagCapacityWarning] ℹ️ pct ${(pct * 100).toStringAsFixed(1)}% < 90% — warning suppressed (working as intended)',
        );
        return const SizedBox.shrink();
      }

      final usedPct = (pct * 100).round();
      HelperMethods.printDebug(
        '🛍️ [BagCapacityWarning] 🔴 RENDERING WARNING — $used/$capacity ($usedPct%)',
      );

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD),
          border: Border.all(color: const Color(0xFFFFB300), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFE65100),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bag almost full ($used / $capacity — $usedPct%)',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7B4F00),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Please contact the runner boy to collect the bag, '
                    'submit this bag to the lab, or use a new bag for '
                    'further registrations.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7B4F00),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
