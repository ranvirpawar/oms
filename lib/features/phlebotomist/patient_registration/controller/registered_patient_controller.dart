// controllers/registered_patient_controller.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lifenity_connect/utils/ui_designs/liquid_snackbar.dart'
    hide SnackPosition;

import '../models/registered_patient_model.dart';
import '../service/patient_registration_service.dart';

class RegisteredPatientController extends GetxController {
  final PatientRegistrationService patientRegistrationService =
      PatientRegistrationService();

  // Observable variables
  final RxList<Map<String, dynamic>> groupedPatients =
      <Map<String, dynamic>>[].obs;

  // NEW: Keep the original full list (after date filtering)
  final RxList<Map<String, dynamic>> _allPatients =
      <Map<String, dynamic>>[].obs;

  final RxBool isLoading = false.obs;
  final RxString facilityName = ''.obs;
  final RxString facilityId = ''.obs;
  final Rx<DateTime> fromDate = DateTime.now()
      .subtract(const Duration(days: 7))
      .obs;
  final Rx<DateTime> toDate = DateTime.now().obs;
  final RxSet<String> expandedBarcodes = <String>{}.obs;
// In RegisteredPatientController, add these observables:
  final RxBool isMobileVerified = true.obs;
  final RxBool isMobileVerifying = false.obs;
  final RxString mobileNumberError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Get arguments passed from previous screen
    final args = Get.arguments;
    if (args != null) {
      facilityId.value = args['facilityId'].toString();
      facilityName.value = args['facilityName'] ?? 'Patient Registration';

      if (args['fromDate'] != null) {
        fromDate.value = args['fromDate'];
      }
      if (args['toDate'] != null) {
        toDate.value = args['toDate'];
      }
    }

    fetchPatients();
  }

  Future<void> fetchPatients() async {
    isLoading.value = true;
    try {
      final response = await patientRegistrationService.fetchRegisteredPatients(
        facilityId: facilityId.value,
        fromDate: fromDate.value,
        toDate: toDate.value,
      );

      if (response != null && response.status == 'Success') {
        _groupPatientsByBarcode(response.output);
      } else {
        debugPrint(
          'Error fetching patients: ${response?.message ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      // SnackBarService.to.showMessage(
      //   message: 'Something went wrong. Please try again',
      // );
    } finally {
      isLoading.value = false;
    }
  }

  void _groupPatientsByBarcode(List<RegisteredPatient> patients) {
    final Map<String, List<RegisteredPatient>> grouped = {};

    for (var patient in patients) {
      if (!grouped.containsKey(patient.orderno)) {
        grouped[patient.orderno] = [];
      }
      grouped[patient.orderno]!.add(patient);
    }

    final List<Map<String, dynamic>> result = grouped.entries.map((entry) {
      final firstPatient = entry.value.first;
      return {
        'barcode': entry.key,
        'fullname': firstPatient.fullname,
        'age': firstPatient.age,
        'adddate': firstPatient.parsedDate,
        'tests': entry.value,
      };
    }).toList();

    // Sort by date (newest first)
    result.sort((a, b) {
      final dateA = a['adddate'] as DateTime?;
      final dateB = b['adddate'] as DateTime?;
      if (dateA == null || dateB == null) return 0;
      return dateB.compareTo(dateA);
    });

    // Store original full list
    _allPatients.value = result;

    // Apply current search filter (if any)
    _applyCurrentFilter();
  }

  void _applyCurrentFilter() {
    final query = searchQuery.value.trim().toLowerCase();

    if (query.isEmpty) {
      groupedPatients.value = List.from(
        _allPatients,
      ); // copy to avoid reference issues
      return;
    }

    final filtered = _allPatients.where((patient) {
      final barcode = (patient['barcode'] as String).toLowerCase();
      final fullName = (patient['fullname'] as String).toLowerCase();

      final tests = patient['tests'] as List<RegisteredPatient>;
      final mobile = tests.isNotEmpty
          ? tests.first.mobile?.toLowerCase() ?? ''
          : '';
      // opd number as well
      final opdNumber = tests.isNotEmpty
          ? tests.first.opdNumber?.toLowerCase() ?? ''
          : '';

      return barcode.contains(query) ||
          fullName.contains(query) ||
          mobile.contains(query) ||
          opdNumber.contains(query);
    }).toList();

    groupedPatients.value = filtered;
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
    _applyCurrentFilter();
  }

  // Called when user clears search
  void clearSearch() {
    searchQuery.value = '';
    _applyCurrentFilter(); // Just restore original list - NO API CALL
  }

  void toggleExpanded(String barcode) {
    if (expandedBarcodes.contains(barcode)) {
      expandedBarcodes.remove(barcode);
    } else {
      expandedBarcodes.add(barcode);
    }
  }

  bool isExpanded(String barcode) {
    return expandedBarcodes.contains(barcode);
  }

  // In RegisteredPatientController, add:

  Future<void> updatePatient({
    required String orderId,
    required String opdNumber,
    required String basicReceipt,
    required String advanceReceipt,
    required String patientType,
    required String mobile,
    required String importStat,
  }) async {
    isLoading.value = true;
    try {
      final result = await patientRegistrationService.updatePatientOpdReceipt(
        orderId: orderId,
        opdNumber: opdNumber,
        basicReceipt: basicReceipt,
        advanceReceipt: advanceReceipt,
        patientType: patientType,
        mobile: mobile,
        importStat: importStat,
      );
      if (result) {
        Get.back();
        Get.back();

        fetchPatients();
        LiquidSnack.success('Patient updated successfully');
      } else {
        LiquidSnack.error('Update failed. Please try again.');
      }
    } catch (e) {
      // SnackBarService.to.showMessage(
      //   message: 'Something went wrong. Please try again.',
      // );
    } finally {
      isLoading.value = false;
    }
  }



  Future<void> validateMobileNumber(String mobileNumber, String? originalMobile) async {
    // Skip validation if mobile hasn't changed
    if (mobileNumber == originalMobile) {
      isMobileVerified.value = true;
      mobileNumberError.value = '';
      return;
    }
    if (mobileNumber.length != 10) {
      isMobileVerified.value = false;
      mobileNumberError.value = 'Enter a valid 10-digit mobile number';
      return;
    }
    try {
      isMobileVerifying.value = true;
      final response = await patientRegistrationService.validateMobileNumber(mobileNumber);
      if (response['status'] == 'Success') {
        if (response['output'][0]['MobExistCount'] > 6) {
          mobileNumberError.value = 'Mobile number already registered for 6 members';
          isMobileVerified.value = false;
        } else {
          isMobileVerified.value = true;
          mobileNumberError.value = '';
        }
      } else {
        mobileNumberError.value = response['message'] ?? 'Validation failed';
        isMobileVerified.value = false;
      }
    } catch (e) {
      mobileNumberError.value = 'Error validating mobile number';
      isMobileVerified.value = false;
    } finally {
      isMobileVerifying.value = false;
    }
  }
  Future<void> selectFromDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fromDate.value,
      firstDate: DateTime(2020),
      lastDate: toDate.value,
    );

    if (picked != null) {
      fromDate.value = picked;
      fetchPatients(); // Only date change should call API
    }
  }

  Future<void> selectToDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: toDate.value,
      firstDate: fromDate.value,
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      toDate.value = picked;
      fetchPatients();
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(date);
  }

  void refreshData() {
    fetchPatients();
  }

  // Add these observables
  final RxString searchQuery = ''.obs;

  // Add this method
  void filterPatients() {
    final query = searchQuery.value.trim().toLowerCase();

    if (query.isEmpty) {
      fetchPatients();
      return;
    }

    final filtered = groupedPatients.where((patient) {
      final barcode = (patient['barcode'] as String).toLowerCase();
      final fullName = (patient['fullname'] as String).toLowerCase();

      final tests = patient['tests'] as List<RegisteredPatient>;
      final mobile = tests.isNotEmpty
          ? tests.first.mobile?.toLowerCase()
          : null;

      return barcode.contains(query) ||
          fullName.contains(query) ||
          (mobile?.contains(query) ?? false);
    }).toList();

    groupedPatients.value = filtered;
  }

  // opd number verify
  // Inside RegisteredPatientController

  final RxBool isOPDVerifying = false.obs;
  final RxBool isOpdVerified = true.obs; // Start as true by default
  Timer? _debounce;

  Future<void> autoVerifyOpd(String newOpd, String? originalOpd) async {
    // Cancel previous debounce
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Case 1: Empty OPD → Not allowed
    if (newOpd.trim().isEmpty) {
      isOpdVerified.value = false;
      isOPDVerifying.value = false;
      return;
    }

    // Case 2: Same as original → Valid (no need to call API)
    if (newOpd.trim() == (originalOpd ?? '').trim()) {
      isOpdVerified.value = true;
      isOPDVerifying.value = false;
      return;
    }

    // Case 3: New OPD → Verify with debounce
    isOPDVerifying.value = true;
    isOpdVerified.value = false; // Reset until verified

    _debounce = Timer(const Duration(milliseconds: 600), () async {
      try {
        final exists = await patientRegistrationService.checkOpdNumberExists(
          newOpd.trim(),
          facilityId.value,
        );

        isOpdVerified.value = !exists;

        if (exists) {
          LiquidSnack.warning('OPD number already exists!');
        }
      } catch (e) {
        isOpdVerified.value = false;
        debugPrint('OPD verification error: $e');
      } finally {
        isOPDVerifying.value = false;
      }
    });
  }
}
