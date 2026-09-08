import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_recollection/model/rejection_reason_model.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_recollection/model/test_recollection_model.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../network/app_urls.dart';
import '../../../../services/snackbar_service.dart';
import '../../../../services/user_service.dart';
import '../../../../theme/app_colors.dart';
import '../../patient_registration/service/patient_registration_service.dart';
import '../model/rejected_tests_model.dart';
import '../service/sample_recollection_service.dart';

class RecollectTestsController extends GetxController {
  // is loading
  var isLoading = false.obs;
  RxString visitCode = ''.obs;
  final RxString empId = ''.obs;
  RxBool isScanning = false.obs;
  final MobileScannerController scannerController = MobileScannerController();

  // rejected test lists
  RxList<RejectedTests> rejectedTestsList = <RejectedTests>[].obs;

  // selected tests
  RxList<RejectedTests> selectedTests = <RejectedTests>[].obs;

  // deny remark list
  RxList<DenyRemarkModel> denyRemarkList = <DenyRemarkModel>[].obs;

  // selected deny remark
  Rx<DenyRemarkModel?> selectedDenyRemark = Rx<DenyRemarkModel?>(null);

  // Services
  final SampleRecollectionService _service = Get.put(
    SampleRecollectionService(),
  );

  // user service
  final userService = Get.put(UserService());

  // patient registration service
  final patientRegistrationService = Get.put(PatientRegistrationService());

  @override
  void onInit() {
    super.onInit();
    // get test from arguments
    final args = Get.arguments as RecollectionTestListUpdated;
    visitCode.value = args.visitCode.toString() ?? '';
    debugPrint('Visit code: ${visitCode.value}');
    fetchRejectedTests();
    fetchDenyRemarks();
    loadUser();
  }

  void loadUser() async {
    try {
      final userProfile = await userService.getUserProfile();
      empId.value = userProfile?.empCode.toString() ?? '';
      debugPrint('✅ Loaded user empId: ${empId.value}');
    } catch (e) {
      debugPrint('❌ Error loading user: $e');
    }
  }

  // fetch rejected tests
  Future<void> fetchRejectedTests() async {
    try {
      isLoading.value = true;

      final response = await _service.getRejectedTestDetails(
        visitCode: visitCode.value,
      );

      rejectedTestsList.assignAll(response);

      if (response.isEmpty) {
        SnackBarService.to.showMessage(
          message: 'No tests found for the selected date range',
        );
      }
    } catch (e) {
      SnackBarService.to.showMessage(message: 'Failed to fetch test data');
      debugPrint('Error fetching test data : $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchDenyRemarks() async {
    try {
      isLoading.value = true;

      final response = await _service.fetchRejectionRemarks();

      denyRemarkList.assignAll(response);

      if (response.isEmpty) {
        SnackBarService.to.showMessage(message: 'No deny remarks found');
      }
    } catch (e) {
      SnackBarService.to.showMessage(message: 'Failed to fetch deny remarks');
      debugPrint('Error fetching deny remarks : $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> makeCall(String mobile) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: mobile);
    try {
      await launchUrl(phoneUri);
    } catch (e) {
      SnackBarService.to.showMessage(message: 'Could not launch phone dialer');
    }
  }

  void toggleTestSelection(RejectedTests test) {
    final isSelected = selectedTests.any(
      (t) => t.serviceCode == test.serviceCode,
    );
    final isSugarTest = [969, 970, 971].contains(test.serviceCode);

    // Check for conflicts before adding
    if (!isSelected && selectedTests.isNotEmpty) {
      final hasExistingSugarTests = selectedTests.any(
        (t) => [969, 970, 971].contains(t.serviceCode),
      );
      final hasExistingNonSugarTests = selectedTests.any(
        (t) => ![969, 970, 971].contains(t.serviceCode),
      );

      // Prevent mixing sugar and non-sugar tests
      if (isSugarTest && hasExistingNonSugarTests) {
        SnackBarService.to.showMessage(
          message: 'Cannot select sugar tests with other tests',
          backgroundColor: Colors.orange,
        );
        return;
      } else if (!isSugarTest && hasExistingSugarTests) {
        SnackBarService.to.showMessage(
          message: 'Cannot select other tests with sugar tests',
          backgroundColor: Colors.orange,
        );
        return;
      }
    }

    // Special logic for test IDs 969, 970, 971 — only one can be selected
    if ([969, 970, 971].contains(test.serviceCode)) {
      if (isSelected) {
        // If the test is already selected, remove it
        selectedTests.removeWhere((t) => t.serviceCode == test.serviceCode);
        debugPrint('❌ Removed ${test.serviceCode}');
      } else {
        // Remove any other tests from the group (969, 970, 971)
        selectedTests.removeWhere(
          (t) => [969, 970, 971].contains(t.serviceCode),
        );
        // Add the newly selected test
        selectedTests.add(test);
        debugPrint('✅ Added ${test.serviceCode}');
      }
    }
    // Special logic for test ID 3001 and 3033 — treat them as linked
    /*else if (test.serviceCode == 3001 || test.serviceCode == 3033) {
      if (isSelected) {
        // Remove both if one is being deselected
        selectedTests.removeWhere((t) => t.serviceCode == 3001 || t.serviceCode == 3033);
        debugPrint('❌ Removed both 3001 and 3033');
      } else {
        // Add both if not already selected
        // First, remove any existing instances
        selectedTests.removeWhere((t) => t.serviceCode == 3001 || t.serviceCode == 3033);

        // Add the current test
        selectedTests.add(test);

        // Find and add the linked test if it exists in rejectedTestsList
        final linkedTestCode = test.serviceCode == 3001 ? 3033 : 3001;
        final linkedTest = rejectedTestsList.firstWhereOrNull((t) => t.serviceCode == linkedTestCode);

        if (linkedTest != null) {
          selectedTests.add(linkedTest);
          debugPrint('✅ Added both ${test.serviceCode} and $linkedTestCode');
        } else {
          debugPrint('✅ Added ${test.serviceCode} (linked test $linkedTestCode not found in rejected list)');
        }
      }
    }*/
    // Normal toggle behavior for all other tests
    else {
      final existingIndex = selectedTests.indexWhere(
        (t) => t.serviceCode == test.serviceCode,
      );

      if (existingIndex != -1) {
        selectedTests.removeAt(existingIndex);
        debugPrint('❌ Removed ${test.serviceCode}');
      } else {
        selectedTests.add(test);
        debugPrint('✅ Added ${test.serviceCode}');
      }
    }
  }

  bool isTestSelected(RejectedTests test) {
    return selectedTests.any((t) => t.serviceCode == test.serviceCode);
  }

  void clearAllSelections() {
    selectedTests.clear();
  }

  void selectAllTests() {
    selectedTests.clear();

    // Add all tests while respecting special rules
    for (final test in rejectedTestsList) {
      final testCode = test.serviceCode;

      // For tests 969, 970, 971 - only add the first one found
      if ([969, 970, 971].contains(testCode)) {
        final hasAnyFromGroup = selectedTests.any(
          (t) => [969, 970, 971].contains(t.serviceCode),
        );
        if (!hasAnyFromGroup) {
          selectedTests.add(test);
        }
      }
      // For tests 3001 and 3033 - add both if either exists
      else if (testCode == 3001 || testCode == 3033) {
        final hasAnyFromPair = selectedTests.any(
          (t) => t.serviceCode == 3001 || t.serviceCode == 3033,
        );
        if (!hasAnyFromPair) {
          // Add current test
          selectedTests.add(test);

          // Find and add the linked test
          final linkedTestCode = testCode == 3001 ? 3033 : 3001;
          final linkedTest = rejectedTestsList.firstWhereOrNull(
            (t) => t.serviceCode == linkedTestCode,
          );
          if (linkedTest != null &&
              !selectedTests.any((t) => t.serviceCode == linkedTestCode)) {
            selectedTests.add(linkedTest);
          }
        }
      }
      // For all other tests - add normally
      else {
        if (!selectedTests.any((t) => t.serviceCode == testCode)) {
          selectedTests.add(test);
        }
      }
    }

    debugPrint(
      '✅ Selected all tests with special rules applied: ${selectedTests.length} tests selected',
    );
  }

  // service method call to deny recollection
  Future<bool> denyRecollection() async {
    // Validation checks
    if (selectedDenyRemark.value == null) {
      SnackBarService.to.showMessage(
        message: 'Please select a reason for denial',
        backgroundColor: Colors.orange,
      );
      return false;
    }

    if (selectedTests.isEmpty) {
      SnackBarService.to.showMessage(
        message: 'Please select at least one test to deny recollection',
        backgroundColor: Colors.orange,
      );
      return false;
    }

    try {
      isLoading.value = true;

      final response = await _service.denyRecollection(
        visitCode: int.parse(visitCode.value),
        selectedTests: selectedTests,
        denyRemark: selectedDenyRemark.value!.denyRemark,
        userId: empId.value.toString(), // TODO: Replace with actual user ID
      );

      debugPrint('Deny recollection response: $response');

      if (response == true) {
        // Success case
        SnackBarService.to.showMessage(
          message: 'Recollection denied successfully',
          backgroundColor: AppColors.success,
        );

        // Clear selections after successful denial
        clearAllSelections();
        selectedDenyRemark.value = null;

        return true;
      } else {
        // Service returned false - business logic failure
        debugPrint('API returned false - business failure');
        SnackBarService.to.showMessage(
          message: 'Failed to deny recollection. Please try again.',
          backgroundColor: AppColors.warning,
        );
        return false;
      }
    } catch (e) {
      // Handle exceptions
      debugPrint('Error denying recollection: $e');
      SnackBarService.to.showMessage(
        message:
            'Error denying recollection. Please check your connection and try again.',
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> acceptRecollection(String barcode) async {
    // Validation checks
    if (barcode.isEmpty) {
      SnackBarService.to.showMessage(
        message: 'Please enter a valid barcode',
        backgroundColor: Colors.orange,
      );
      return false;
    }

    if (selectedTests.isEmpty) {
      SnackBarService.to.showMessage(
        message: 'Please select at least one test to accept recollection',
        backgroundColor: Colors.orange,
      );
      return false;
    }

    // Check for sugar test conflicts
    final hasSugarTests = selectedTests.any(
      (test) => [969, 970, 971].contains(test.serviceCode),
    );
    final hasNonSugarTests = selectedTests.any(
      (test) => ![969, 970, 971].contains(test.serviceCode),
    );

    if (hasSugarTests && hasNonSugarTests) {
      SnackBarService.to.showMessage(
        message: 'Sugar tests cannot be collected together with other tests',
        backgroundColor: Colors.orange,
      );
      return false;
    }

    try {
      isLoading.value = true;

      final response = await _service.acceptRecollection(
        visitCode: int.parse(visitCode.value),
        selectedTests: selectedTests,
        barcode: barcode,
        userId: empId.value, // TODO: Replace with actual user ID
      );

      debugPrint('Accept recollection response: $response');

      if (response == true) {
        // Success case
        SnackBarService.to.showMessage(
          message: 'Recollection accepted successfully',
          backgroundColor: Colors.green,

        );

        // Clear selections after successful acceptance
        clearAllSelections();

        return true;
      } else {
        // Service returned false - business logic failure
        debugPrint('API returned false - business failure');
        SnackBarService.to.showMessage(
          message: 'Failed to accept recollection. Please try again.',
          backgroundColor: Colors.orange,
        );
        return false;
      }
    } catch (e) {
      // Handle exceptions
      debugPrint('Error accepting recollection: $e');
      SnackBarService.to.showMessage(
        message:
            'Error accepting recollection. Please check your connection and try again.',
        backgroundColor: Colors.red,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Helper method to validate if sugar tests are properly selected
  bool canAcceptRecollection() {
    if (selectedTests.isEmpty) {
      return false;
    }

    final hasSugarTests = selectedTests.any(
      (test) => [969, 970, 971].contains(test.serviceCode),
    );
    final hasNonSugarTests = selectedTests.any(
      (test) => ![969, 970, 971].contains(test.serviceCode),
    );

    // Cannot accept if both sugar and non-sugar tests are selected
    return !(hasSugarTests && hasNonSugarTests);
  }

  Future<bool> checkDuplicateBarcode(String barcode) async {
    try {
      final url = AppUrls.checkBarcode;
      final queryParams = {'ORDERNO': barcode};
      final response = await patientRegistrationService.apiClient.post(
        url,
        data: queryParams,
      );
      final data = response.data;
      // final data = response['data']; old
      if (data['status'] == 'Success' && data['output'] == 0) {
        return true; // Barcode does not exist, valid
      } else {
        /*SnackBarService.to.showMessage(message: "Barcode Already Exists!");*/
        return false;
      }
    } catch (e) {
      // SnackBarService.to.showMessage(
      //   message: 'Something went wrong please try later',
      // );
      return false;
    }
  }
}
