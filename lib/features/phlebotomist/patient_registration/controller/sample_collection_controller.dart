import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_registration/service/patient_registration_service.dart';
import 'package:lifenity_connect/network/app_urls.dart';
import 'package:lifenity_connect/services/auth_manager.dart';
import 'package:lifenity_connect/services/snackbar_service.dart';
import '../../../../componenents/c_textformfeild.dart';
import '../../../../constants/app_assets.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/helper_functions/helper_methods.dart';
import '../bag_status_dashboard/controller/registrarion_bag_controller.dart';
import '../bag_status_dashboard/view/patient_registration_dashboard.dart';
import '../models/doctor_ref_model.dart';
import '../models/doctor_reference.dart';
import '../models/tests_model.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../service/trf_upload_service.dart';

class TestBarcodeController extends GetxController {
  final PatientRegistrationService patientRegistrationService =
      Get.put(PatientRegistrationService());
  final AuthManager authManager = Get.put(AuthManager());
  final MobileScannerController scannerController = MobileScannerController();

  // Bag id from previous page
  final RxString bagId = ''.obs;
  final RxString sessionID = ''.obs;


  // Selected tests from previous page
  final RxList<TestModel> selectedTests = <TestModel>[].obs;
  final RxMap<String, dynamic> patientArray = <String, dynamic>{}.obs;

  // Barcode fields for specific tests
  final RxMap<String, TextEditingController> barcodeControllers =
      <String, TextEditingController>{}.obs;

  // Tube requirements with counts and editable quantities
  final RxMap<String, RxMap<String, dynamic>> tubeRequirements =
      <String, RxMap<String, dynamic>>{}.obs;

  // Loading states for basic and advanced tests
  final RxBool hasBasicTests = false.obs;
  final RxBool hasAdvancedTests = false.obs;

  // receiptNumberController to basicReceiptNumberController
  final TextEditingController basicReceiptNumberController =
      TextEditingController();
  final TextEditingController advancedReceiptNumberController =
      TextEditingController();

// TRF Upload properties
  final TrfUploadService trfUploadService = Get.put(TrfUploadService());
  final ImagePicker _imagePicker = ImagePicker();
  final RxList<File> selectedTrfFiles = <File>[].obs;
  final RxBool isUploadingTrf = false.obs;

  // Loading state
  final RxBool isProcessing = false.obs;

  final Rx<TimeOfDay> selectedTime = TimeOfDay.now().obs;
  final mainBarcodeController = TextEditingController();
  final glucoseBarcodeController = TextEditingController();
  final RxList<DoctorReference> doctorReferences = <DoctorReference>[].obs;
  final RxList<ReferenceDoctor> doctorNames = <ReferenceDoctor>[].obs;

  // Observable variables for barcode validation
  final RxBool isMainBarcodeValid = true.obs;
  final RxString mainBarcodeError = ''.obs;
  final RxBool isGlucoseBarcodeValid = true.obs;
  final RxString glucoseBarcodeError = ''.obs;
  final RxBool isScanning = false.obs;
  final Rx<ReferenceDoctor?> selectedDoctor = Rx<ReferenceDoctor?>(null);

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();

  RxString empId = ''.obs;
  RxString selectedFacilityId = ''.obs;
  final RxBool hasHmisTests = false.obs;
  final TextEditingController hmisVoucherController = TextEditingController();
  final RxString requisitionDNO = ''.obs;
  final BagRegistrationController bagController =
      Get.find<BagRegistrationController>();

  @override
  void onInit() {
    super.onInit();

    kPrint('🔄 TestBarcodeController initialized');
    kPrint('-----------------------------------------');
    kPrint(
        'bag  Id : ${bagController.currentSession.value?.bagId.toString()}');
    bagId.value = bagController.currentSession.value?.bagId.toString() ?? '';

    kPrint(
        'session  Id : ${bagController.currentSession.value?.sessionID.toString()}');
    sessionID.value =
        bagController.currentSession.value?.sessionID.toString() ?? '';


    if (!bagController.isBagOpen.value) {
      /// todo
      // Bag was closed externally, go back to dashboard
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.until((route) {
          return route.settings.name ==
              const PatientRegistrationDashboard().runtimeType.toString();
        });

        Get.snackbar(
            'Session Ended', 'The bag was closed. Please open a bag first.');
      });
    }

    getUserdata();
    calculateTubeRequirements();
// Add listeners for real-time barcode validation
    mainBarcodeController.addListener(() {
      _handleBarcodeInput(mainBarcodeController.text, isMainBarcode: true);
    });
    glucoseBarcodeController.addListener(() {
      _handleBarcodeInput(glucoseBarcodeController.text, isMainBarcode: false);
    });
  }

  void getUserdata() {
    authManager.getUserData().then((data) {
      kPrint('📅user data from auth');
      if (data != null) {
        data.forEach((key, value) {
          kPrint('$key: $value');
        });
        // Store empId if available
        final user = data['user'];
        if (user != null && user.containsKey('EmpCode')) {
          empId.value = user['EmpCode'].toString();
          kPrint(empId.value);
          fetchDoctorReferences();
          kPrint('✅ empId set: ${empId.value}');
        } else {
          kPrint('❌ EmpCode not found in user data');
        }
      } else {
        kPrint('No user data found');
      }
    }).catchError((err) {
      kPrint('Error loading user data: $err');
    });
  }

  void _handleBarcodeInput(String input, {required bool isMainBarcode}) {
    final controller =
        isMainBarcode ? mainBarcodeController : glucoseBarcodeController;
    final isCheckingObs =
        isMainBarcode ? isMainBarcodeChecking : isGlucoseBarcodeChecking;
    final apiValidObs =
        isMainBarcode ? mainBarcodeApiValid : glucoseBarcodeApiValid;
    final errorObs = isMainBarcode ? mainBarcodeError : glucoseBarcodeError;
    final validObs = isMainBarcode ? isMainBarcodeValid : isGlucoseBarcodeValid;

    // Remove all non-digit characters
    String digitsOnly = input.replaceAll(RegExp(r'[^0-9]'), '');

    // Limit to 12 digits
    if (digitsOnly.length > 12) {
      digitsOnly = digitsOnly.substring(0, 12);
    }

    // Final value to be stored in controller
    final String finalText = 'AC$digitsOnly';

    // Avoid infinite loop by checking if different
    if (controller.text != finalText) {
      controller.value = TextEditingValue(
        text: finalText,
        selection: TextSelection.collapsed(offset: finalText.length),
      );
    }

    // Reset states
    apiValidObs.value = false;
    isCheckingObs.value = false;

    if (finalText.isEmpty) {
      errorObs.value = '';
      validObs.value = true;
      return;
    }

    if (!_validateBarcodeFormat(finalText, isMainBarcode: isMainBarcode)) {
      return;
    }
    // ❌ Duplicate barcode check
    final otherBarcode = isMainBarcode
        ? glucoseBarcodeController.text
        : mainBarcodeController.text;
    if (otherBarcode.isNotEmpty && finalText == otherBarcode) {
      errorObs.value = 'Barcodes cannot be the same';
      validObs.value = false;
      return;
    }

    if (finalText.length == 14 &&
        finalText.startsWith('AC') &&
        RegExp(r'^AC\d{12}$').hasMatch(finalText)) {
      isCheckingObs.value = true;
      _checkBarcodeAPI(finalText, isMainBarcode: isMainBarcode);
    }
  }

  bool hasGlucoseTests() {
    return selectedTests.any((test) =>
            test.testName?.toLowerCase().contains('glucose') ==
            true /*||
        test.testName?.toLowerCase().contains('sugar') == true*/
        );
  }

  bool hasNonGlucoseTests() {
    return selectedTests.any((test) =>
        !(test.testName?.toLowerCase().contains('glucose') ==
            true /*||
            test.testName?.toLowerCase().contains('sugar') == true)*/
        ));
  }

  bool shouldShowMainBarcode() {
    return hasNonGlucoseTests();
  }

  bool shouldShowGlucoseBarcode() {
    return hasGlucoseTests();
  }

  String getMainBarcodeLabel() {
    if (hasGlucoseTests() && hasNonGlucoseTests()) {
      return 'Barcode';
    } else {
      return 'Barcode';
    }
  }

  String getGlucoseBarcodeLabel() {
    return 'Sugar/Glucose Barcode';
  }

  final RxBool isMainBarcodeChecking = false.obs;
  final RxBool isGlucoseBarcodeChecking = false.obs;
  final RxBool mainBarcodeApiValid = false.obs;
  final RxBool glucoseBarcodeApiValid = false.obs;

  bool _validateBarcodeFormat(String barcode, {required bool isMainBarcode}) {
    final label = isMainBarcode ? 'Barcode' : 'Glucose Barcode';
    final errorObs = isMainBarcode ? mainBarcodeError : glucoseBarcodeError;
    final validObs = isMainBarcode ? isMainBarcodeValid : isGlucoseBarcodeValid;

    if (barcode.length > 14) {
      errorObs.value = '$label cannot exceed 14 characters (AC + 12 digits)';
      validObs.value = false;
      return false;
    }

    if (barcode.length > 2 && !RegExp(r'^AC\d*$').hasMatch(barcode)) {
      errorObs.value = '$label must contain only digits after "AC"';
      validObs.value = false;
      return false;
    }

    if (barcode.length < 14) {
      errorObs.value = '$label needs ${14 - barcode.length} more digits';
      validObs.value = false;
      return false;
    }

    errorObs.value = '';
    validObs.value = true;
    return true;
  }

  Future<void> _checkBarcodeAPI(String barcode,
      {required bool isMainBarcode}) async {
    final isCheckingObs =
        isMainBarcode ? isMainBarcodeChecking : isGlucoseBarcodeChecking;
    final apiValidObs =
        isMainBarcode ? mainBarcodeApiValid : glucoseBarcodeApiValid;
    final errorObs = isMainBarcode ? mainBarcodeError : glucoseBarcodeError;

    try {
      final isValid = await _checkDuplicateBarcode(barcode);
      isCheckingObs.value = false;

      if (isValid) {
        apiValidObs.value = true;
        errorObs.value = '';
      } else {
        apiValidObs.value = false;
        errorObs.value = 'Barcode already exists';
      }
    } catch (e) {
      isCheckingObs.value = false;
      apiValidObs.value = false;
      errorObs.value = 'Failed to validate barcode';
    }
  }

// Widget method to build suffix icon
  Widget buildSuffixIcon({required bool isMainBarcode}) {
    // Always show scanner icon when no error and not validated
    return GestureDetector(
      onTap: () => openBarcodeScanner(isMainBarcode: isMainBarcode),
      child: const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 24),
    );
  }

  Future<void> fetchDoctorReferences() async {
    try {
      final response = await patientRegistrationService.fetchReferenceDoctors(
        facilityCode: facilityId.value,
      );
      doctorNames.assignAll(response);
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch doctor references: $e');
    }
  }

  void initializeWithSelectedTests(
    List<TestModel> tests,
    Map<String, dynamic> patientData,
    String? requisitionDno,
      String? hmisVoucherNumber,
  ) {
    selectedTests.assignAll(tests);
    patientArray.assignAll(patientData);
    // Determine if we have basic (mobCatCode 1 or 2) or advanced (mobCatCode 3) tests
    hasBasicTests.value = tests.any(
        (test) => test.testCategoryCode == 1 || test.testCategoryCode == 2);
    hasAdvancedTests.value = tests.any((test) => test.testCategoryCode == 3);
    //  HMIS detection
    hasHmisTests.value = tests.any((test) => test.hmisData != null);
    requisitionDNO.value = requisitionDno ?? '';
    if (kDebugMode) {
      kPrint('🔢 requisition value set in sample controller: $requisitionDNO');
    }


    final voucher = hmisVoucherNumber?.isNotEmpty == true
        ? hmisVoucherNumber!
        : tests
        .firstWhereOrNull((t) => t.hmisData != null)
        ?.hmisData?['VoucherNumber']
        ?.toString() ??
        '';
    if (kDebugMode) {
      kPrint('🔢 voucher value set in sample controller: $voucher');
    }

    if (hasHmisTests.value && voucher.isNotEmpty) {
      hmisVoucherController.text = voucher;
    }

    // Auto-fill both receipt number fields when HMIS tests are present
    if (voucher.isNotEmpty) {
      if (hasBasicTests.value) basicReceiptNumberController.text = voucher;
      if (hasAdvancedTests.value) advancedReceiptNumberController.text = voucher;
    }
    calculateTubeRequirements();
    assignPatientValues(patientArray);
  }

  RxString patientFirstName = ''.obs;
  RxString patientLastName = ''.obs;
  RxString facilityId = ''.obs;

  void assignPatientValues(Map<String, dynamic> patientData) {
    // Safely get the first patient from the list
    final patient = patientData['patientArray']?[0];
    if (patient == null) {
      kPrint('❌ No patient found in array');
      return;
    }

    // Assign to TextEditingControllers
    patientFirstName.value = patient['firstName'] ?? '';
    patientLastName.value = patient['lastName'] ?? '';
    facilityId.value = patient['facilityId'] ?? '';

    kPrint(facilityId.value);

    kPrint('✅ Patient values assigned successfully');
  }

  void calculateTubeRequirements() {
    tubeRequirements.clear();
    final Map<String, List<TestModel>> groupedByTube = {};

    for (var test in selectedTests) {
      final tubeContent = test.tubeContent ?? 'Unknown';
      if (!groupedByTube.containsKey(tubeContent)) {
        groupedByTube[tubeContent] = [];
      }
      groupedByTube[tubeContent]!.add(test);
    }

    for (var entry in groupedByTube.entries) {
      final tubeType = entry.key;
      final tests = entry.value;
      tubeRequirements[tubeType] = <String, dynamic>{
        'testCount': tests.length,
        'requiredQuantity': RxInt(1),
        'tests': tests,
        'tubeId': tests.first.tubeId,
      }.obs;
    }
  }

  void updateTubeQuantity(String tubeType, int quantity) {
    if (tubeRequirements.containsKey(tubeType)) {
      tubeRequirements[tubeType]!['requiredQuantity'].value = quantity;
    }
  }

  /*Future<bool> _checkDuplicateBarcode(String barcode) async {
    try {
      final url = AppUrls.checkBarcode;
      final queryParams = {'ORDERNO': barcode};
      final response = await patientRegistrationService.apiClient
          .post(url, data: queryParams);
      final data = response.data;
      if (data['status'] == 'Success' && data['output'] == 0) {
        return true; // Barcode does not exist, valid
      } else {
        SnackBarService.to.showMessage(message: 'Barcode Already Exits!');
        mainBarcodeController.clear();
        glucoseBarcodeController.clear();
        return false;
      }
    } catch (e) {
      SnackBarService.to
          .showMessage(message: 'Something went wrong please try later');
      return false;
    }
  }*/
  Future<bool> _checkDuplicateBarcode(String barcode) async {
    try {
      final url = AppUrls.checkBarcode;
      final queryParams = {'ORDERNO': barcode};

      final response = await patientRegistrationService.apiClient.post(
        url,
        data: queryParams,
      );

      final data = response.data;

      final status = data['status'];
      final output = data['output'];

      // Barcode does NOT exist → valid/new barcode
      if (status == 'Fail' &&
          output is List &&
          output.isEmpty) {
        return true;
      }

      // Barcode already exists
      if (status == 'Success' &&
          output is List &&
          output.isNotEmpty) {
        SnackBarService.to.showMessage(
          message: 'Barcode Already Exists!',
        );

        mainBarcodeController.clear();
        glucoseBarcodeController.clear();

        return false;
      }

      // Unexpected API response
      SnackBarService.to.showMessage(
        message: 'Unable to verify barcode. Please try again.',
      );

      return false;
    } catch (e) {
      // SnackBarService.to.showMessage(
      //   message: 'Something went wrong. Please try later.',
      // );

      return false;
    }
  }

  Map<String, dynamic> getLabTestMasterArray(
      Map<String, dynamic> patientArray, String patientPermanentId) {
    final firstPatient = patientArray['patientArray']?.isNotEmpty == true
        ? patientArray['patientArray'][0]
        : {};

    final sampleCount = tubeRequirements.entries.fold<int>(
      0,
      (sum, entry) => sum + (entry.value['requiredQuantity'].value as int),
    );

    final referenceDoctor = selectedDoctor.value != null
        ? selectedDoctor.value!.refDocCode.toString()
        : '';

    // Get receipt numbers
    final String basicReceipt = basicReceiptNumberController.text.trim();
    final String advancedReceipt = advancedReceiptNumberController.text.trim();

    final labTestArray = selectedTests.asMap().entries.map((entry) {
      final index = entry.key;
      final test = entry.value;

      // ✅ Assign receipt number based on test category
      String receiptNumber = '';

      if (test.hmisData != null) {
        // HMIS test → use HMIS voucher
        receiptNumber = hmisVoucherController.text.trim();
      } else if (test.testCategoryCode == 1 || test.testCategoryCode == 2) {
        // Basic tests
        receiptNumber = basicReceipt;
      } else if (test.testCategoryCode == 3) {
        // Advanced tests
        receiptNumber = advancedReceipt;
      }

      return {
        'assignDate': DateFormat('dd/MM/yyyy').format(DateTime.now()),
        'labTestResultMasterId': '6',
        'testId': test.testId.toString(),
        'testResultId': (13 + index).toString(),
        'requistion_dno': requisitionDNO.value, //ToDO testing

        'test_receipt_number': receiptNumber, // ✅ String, not array!
      };
    }).toList();

    final Map<String, dynamic> master = {
      'sampleCount': sampleCount.toString(),
      'patientId': firstPatient['patientId'] ?? '',
      'collectionTime': '${selectedTime.value.hour.toString().padLeft(2, '0')}:${selectedTime.value.minute.toString().padLeft(2, '0')}',
      'labTestResultMasterId': '6',
      'collectionDate': DateFormat('dd/MM/yyyy').format(DateTime.now()),
      'barcode': mainBarcodeController.text.trim(),
      'sugar_barcode': glucoseBarcodeController.text.trim(),
      'referenceDoctor': referenceDoctor,
      'labTestArray': labTestArray,
    };
// ✅ Add patientPermanentId into every patient entry
    final updatedPatientArray = (patientArray['patientArray'] as List?)
            ?.map((p) => {
                  ...p,
                  'patientPermid': patientPermanentId,
                })
            .toList() ??
        [];
    return {
      'labTestMasterArray': [master],
      'patientArray': updatedPatientArray,
    };
  }

 /* Map<String, dynamic> getLabTestMasterArray(
      Map<String, dynamic> patientArray) {
    final firstPatient = patientArray['patientArray']?.isNotEmpty == true
        ? patientArray['patientArray'][0]
        : {};

    final sampleCount = tubeRequirements.entries.fold<int>(
      0,
      (sum, entry) => sum + (entry.value['requiredQuantity'].value as int),
    );
    final referenceDoctor = selectedDoctor.value != null
        ? selectedDoctor.value!.refDocCode.toString()
        : '';


    final labTestArray = selectedTests.asMap().entries.map((entry) {
      final index = entry.key;
      final test = entry.value;
      return {
        'assignDate': DateFormat('dd/MM/yyyy').format(DateTime.now()),
        'labTestResultMasterId': '6', // Placeholder
        'testId': test.testId.toString(),
        'testResultId': (13 + index).toString(),
      };
    }).toList();

    // Build receipt number list
    final List<String> receiptNumbers = [];

    final basicReceipt = basicReceiptNumberController.text.trim();
    final advancedReceipt = advancedReceiptNumberController.text.trim();

    if (hasBasicTests.value && basicReceipt.isNotEmpty) {
      receiptNumbers.add(basicReceipt);
    }

    if (hasAdvancedTests.value && advancedReceipt.isNotEmpty) {
      receiptNumbers.add(advancedReceipt);
    }

    final Map<String, dynamic> master = {
      'sampleCount': sampleCount.toString(),
      'patientId': firstPatient['patientId'] ?? '',
      'collectionTime': selectedTime.value.hour.toString().padLeft(2, '0') +
          ':' +
          selectedTime.value.minute.toString().padLeft(2, '0'),
      'labTestResultMasterId': '6',
      'barcode': mainBarcodeController.text.trim(),
      'sugar_barcode': glucoseBarcodeController.text.trim(),
      'referenceDoctor': referenceDoctor,
      'labTestArray': labTestArray,
    };

    // Only add test_receipt_number if list is not empty
    if (receiptNumbers.isNotEmpty) {
      master['test_receipt_number'] = receiptNumbers;
    }

    return {
      'labTestMasterArray': [master],
      'patientArray': patientArray['patientArray'] ?? [],
    };
  }*/

  String get validBarcode {
    final mainBarcode = mainBarcodeController.text.trim();
    final glucoseBarcode = glucoseBarcodeController.text.trim();

    if (mainBarcode.isNotEmpty) return mainBarcode;
    if (glucoseBarcode.isNotEmpty) return glucoseBarcode;

    return ''; // fallback if both are empty
  }

  Map<String, dynamic> getOrderInputPayload(Map<String, dynamic> patientArray) {
    final orderId = validBarcode;
    final firstPatient = patientArray['patientArray']?.isNotEmpty == true
        ? patientArray['patientArray'][0]
        : {};

    final labCode =
        int.tryParse(firstPatient['centerId']?.toString() ?? '1') ?? 1;
    final facilityCode =
        int.tryParse(firstPatient['facilityId']?.toString() ?? '1') ?? 1;

    final List<Map<String, dynamic>> orderInputs = [];
    kPrint('👺 Sample collection bag id : ${bagId.value}');

    // ✅ 1. Add dynamic entries for each tube
    tubeRequirements.forEach((tubeType, tubeData) {
      if (tubeType == 'TRF') return;
      final tubeId = int.tryParse(tubeData['tubeId']?.toString() ?? '1') ?? 1;
      final tubeCount = tubeData['requiredQuantity']?.value ?? 1;
      final bool addBagId = AppUrls.addBagId;
      orderInputs.add({
        'Orderid': orderId,
        'Tubeid': tubeId,
        'TubeCount': tubeCount,
        'CreatedBy': empId.value,
        'Orderdate': DateFormat('dd/MM/yyyy').format(DateTime.now()),
        'Facilitycode': facilityCode,
        'Labcode': labCode,
        'BagId': bagId.value,
        'SessionId': sessionID.value,



      });
    });

    final trfTube = tubeRequirements['TRF'];
    final trfCount =
        trfTube != null ? (trfTube['requiredQuantity']?.value ?? 1) : 1;

    // ✅ 2. Add mandatory Tubeid = 100
    orderInputs.add({
      'Orderid': orderId,
      'Tubeid': 100,
      'TubeCount': trfCount,
      'CreatedBy': empId.value,
      'Orderdate': DateFormat('dd/MM/yyyy').format(DateTime.now()),
      'Facilitycode': facilityCode,
      'Labcode': labCode,
      /* "BagId": 1,*/
    });

    // printing payload before returning

    return {'input': orderInputs};
  }

  @override
  void onClose() {
    for (var controller in barcodeControllers.values) {
      controller.dispose();
    }
    scannerController.dispose();
    mainBarcodeController.dispose();
    glucoseBarcodeController.dispose();
    super.onClose();
  }

  void addNewDoctor() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add New Doctor',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              CFormTextField(
                controller: firstNameController,
                label: 'First Name',
                iconPath: AppAssets.userIcon,
                isRequired: true,
              ),
              const SizedBox(height: 12),
              CFormTextField(
                controller: middleNameController,
                label: 'Middle Name',
                iconPath: AppAssets.userIcon,
                isRequired: false,
              ),
              const SizedBox(height: 12),
              CFormTextField(
                controller: lastNameController,
                label: 'Last Name',
                iconPath: AppAssets.userIcon,
                isRequired: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final first = firstNameController.text.trim();
                    final middle = middleNameController.text.trim();
                    final last = lastNameController.text.trim();

                    if (first.isEmpty || last.isEmpty) {
                      Get.snackbar(
                          'Validation', 'First and Last name are required.');
                      return;
                    }

                    // Show loading
                    Get.dialog(
                      const Center(child: CircularProgressIndicator()),
                      barrierDismissible: false,
                    );

                    final isSuccess =
                        await patientRegistrationService.insertDoctor(
                      firstName: first,
                      middleName: middle,
                      lastName: last,
                      empCode: empId.value,
                      facilityCode: facilityId.value,
                    );
                    Get.back();
                    firstNameController.clear();
                    middleNameController.clear();
                    lastNameController.clear();

                    if (isSuccess) {
                      // Add doctor locally (if needed)

                      Get.back(); // Close bottom sheet
                      SnackBarService.to
                          .showMessage(message: 'Doctor added successfully');
                      fetchDoctorReferences();
                    } else {
                      SnackBarService.to.showMessage(
                          message: 'Failed to add doctor. Try again.');
                    }
                  },
                  /* onPressed: () {
                    final first = firstNameController.text.trim();
                    final middle = middleNameController.text.trim();
                    final last = lastNameController.text.trim();

                    if (first.isEmpty || last.isEmpty) {
                      Get.snackbar(
                          "Validation", "First and Last name are required.");
                      return;
                    }

                    final doctor = patientRegistrationService.insertDoctor(
                        firstName: first,
                        middleName: middle,
                        lastName: last,
                        empCode: empId.value,
                        facilityCode: facilityId.value);
                    */ /*final newDoctor = ReferenceDoctor(
                      refDoctorName: '$first $middle $last'.trim(),
                    );

                    doctorNames.add(newDoctor);
                    selectedDoctor.value = newDoctor;

                    Get.back();*/ /* // Close bottom sheet
                  },*/
                  child: const Text('Add Doctor'),
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  // scanner
  void openBarcodeScanner({required bool isMainBarcode}) {
    isScanning.value = true;

    Get.bottomSheet(
      Container(
        height: Get.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Scan Barcode',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () {
                      isScanning.value = false;
                      Get.back();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: MobileScanner(
                controller: scannerController,
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      _processScanResult(barcode.rawValue!,
                          isMainBarcode: isMainBarcode);
                      break;
                    }
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Position the barcode within the frame to scan',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      isDismissible: false,
    );
  }

  void _processScanResult(String scannedCode, {required bool isMainBarcode}) {
    isScanning.value = false;
    Get.back(); // Close scanner

    // Extract only digits from scanned code
    String digitsOnly = scannedCode.replaceAll(RegExp(r'[^0-9]'), '');

    // Limit to 12 digits and format
    if (digitsOnly.length > 12) {
      digitsOnly = digitsOnly.substring(0, 12);
    }

    final String formattedCode = 'AC$digitsOnly';

    // Set the barcode in appropriate controller
    if (isMainBarcode) {
      mainBarcodeController.text = formattedCode;
    } else {
      glucoseBarcodeController.text = formattedCode;
    }
  }

  /*--------- trf upload provision------------*/
  /// Show image source selection bottom sheet
  Future<void> showImageSourceSelection() async {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Image Source',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(Get.context!)
                              .primaryColor
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: Theme.of(Get.context!).primaryColor,
                        ),
                      ),
                      title: const Text('Camera'),
                      subtitle: const Text('Take a new photo'),
                      onTap: () {
                        Get.back();
                        _pickImageFromCamera();
                      },
                    ),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Theme.of(Get.context!)
                              .primaryColor
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.photo_library,
                          color: Theme.of(Get.context!).primaryColor,
                        ),
                      ),
                      title: const Text('Gallery'),
                      subtitle: const Text('Choose from gallery'),
                      onTap: () {
                        Get.back();
                        _pickImageFromGallery();
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// Pick image from camera
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (photo != null) {
        selectedTrfFiles.add(File(photo.path));
        SnackBarService.to.showMessage(
          message: 'Image added successfully',
        );
      }
    } catch (e) {
      SnackBarService.to.showMessage(
        message: 'Failed to capture image: $e',
      );
    }
  }

  /// Pick images from gallery (supports multiple selection)
  Future<void> _pickImageFromGallery() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (images.isNotEmpty) {
        for (var image in images) {
          selectedTrfFiles.add(File(image.path));
        }
        SnackBarService.to.showMessage(
          message: '${images.length} image(s) added successfully',
        );
      }
    } catch (e) {
      SnackBarService.to.showMessage(
        message: 'Failed to pick images: $e',
      );
    }
  }

  /// Remove file at specific index
  void removeTrfFile(int index) {
    if (index >= 0 && index < selectedTrfFiles.length) {
      selectedTrfFiles.removeAt(index);
      SnackBarService.to.showMessage(
        message: 'Image removed',
      );
    }
  }

  /// Upload all selected TRF files

  Future<bool> uploadTrfFiles() async {
    if (selectedTrfFiles.isEmpty) {
      return true; // No files to upload, proceed
    }

    try {
      isUploadingTrf.value = true;

      // Get patient details
      final firstPatient = patientArray['patientArray']?.isNotEmpty == true
          ? patientArray['patientArray'][0]
          : {};

      final patientName =
          '${patientFirstName.value} ${patientLastName.value}'.trim();
      final barcode = validBarcode;
      final facilityCode =
          facilityId.value; // Get facility code from controller

      if (barcode.isEmpty) {
        SnackBarService.to.showMessage(
          message: 'Barcode is required to upload TRF files',
        );
        return false;
      }

      if (facilityCode.isEmpty) {
        SnackBarService.to.showMessage(
          message: 'Facility code is required to upload TRF files',
        );
        return false;
      }

      kPrint('🔄 Starting TRF upload with:');
      kPrint('   Barcode: $barcode');
      kPrint('   Patient: $patientName');
      kPrint('   Facility: $facilityCode');
      kPrint('   EmpID: ${empId.value}');
      kPrint('   Files: ${selectedTrfFiles.length}');

      // Upload files
      final result = await trfUploadService.uploadMultipleTrfPhotos(
        filePaths: selectedTrfFiles.map((f) => f.path).toList(),
        barcode: barcode,
        patientName: patientName,
        facilityCode: facilityCode,
        creationUID: empId.value,
      );

      final successCount = result['successCount'] as int;
      final failedFiles = result['failedFiles'] as List<String>;
      final totalFiles = result['totalFiles'] as int;

      if (successCount == totalFiles) {
        SnackBarService.to.showMessage(
          message: 'All TRF files uploaded successfully',
        );
        return true;
      } else if (successCount > 0) {
        SnackBarService.to.showMessage(
          message:
              '$successCount/$totalFiles files uploaded. ${failedFiles.length} failed.',
        );
        return true; // Partial success
      } else {
        SnackBarService.to.showMessage(
          message: 'Failed to upload TRF files',
        );
        return false;
      }
    } catch (e, stackTrace) {
      kPrint('❌ Error uploading TRF files: $e');
      kPrint('   Stack trace: $stackTrace');
      SnackBarService.to.showMessage(
        message: 'Error uploading TRF files',
      );
      return false;
    } finally {
      isUploadingTrf.value = false;
    }
  }
}
