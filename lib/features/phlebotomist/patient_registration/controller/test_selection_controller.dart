// Test Selection Controller

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_registration/service/patient_registration_service.dart';
import 'package:lifenity_connect/network/api_client.dart';
import 'package:lifenity_connect/services/snackbar_service.dart';

import '../models/tests_model.dart';
class TestSelectionController extends GetxController {
  // Search bar controller
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  // Observable lists for different test categories
  final RxList<TestModel> basicTests = <TestModel>[].obs;
  final RxList<TestModel> advanceTests = <TestModel>[].obs;

  // Loading states
  final RxBool isLoadingTests = false.obs;

  // Selected tests storage
  final RxList<TestModel> selectedTests = <TestModel>[].obs;

  // Group tests by lab category for each section
  final RxMap<String, List<TestModel>> basicCategorized =
      <String, List<TestModel>>{}.obs;
  final RxMap<String, List<TestModel>> advanceCategorized =
      <String, List<TestModel>>{}.obs;

  // Store original data for search reset functionality
  final RxMap<String, List<TestModel>> originalBasicCategorized =
      <String, List<TestModel>>{}.obs;
  final RxMap<String, List<TestModel>> originalAdvanceCategorized =
      <String, List<TestModel>>{}.obs;

  final RxString searchQuery = ''.obs;
  final RxBool showSelectedTests = false.obs;
  final RxSet<String> expandedCategories = <String>{}.obs;
  final Rx<Map<String, dynamic>> patientArray = Rx<Map<String, dynamic>>({});
  final RxString hmisVoucherNumber = ''.obs;

  final APIClient _apiClient = Get.put(APIClient());
  final PatientRegistrationService _registrationService =
  Get.put(PatientRegistrationService());

  // HMIS Patient flags
  final RxBool isHMISPatient = false.obs;
  final RxString hmisPatientId = ''.obs;
  final RxString requisitionDno = ''.obs;

  // Store HMIS pre-assigned test IDs for auto-selection tracking
  final RxSet<dynamic> hmisPreAssignedTestIds = <dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();

    final arguments = Get.arguments ?? {};

    if (arguments.containsKey('patientArray')) {
      patientArray.value = arguments['patientArray'] ?? {};
      isHMISPatient.value = arguments['isHMISPatient'] ?? false;
      hmisPatientId.value = arguments['patientId'] ?? '';
    } else {
      patientArray.value = arguments;
      isHMISPatient.value = arguments['isHMISPatient'] ?? false;
      hmisPatientId.value = arguments['patientId'] ?? 0;
    }

    if (isHMISPatient.value) {
      // Fetch both HMIS tests and all master tests, then merge
      fetchHMISPatientTestsWithMaster();
    } else {
      fetchAllTests();
    }

    expandedCategories.clear();
  }

  /// Fetches HMIS patient's pre-assigned tests AND all master tests in parallel.
  /// HMIS tests are auto-selected. If an HMIS test's ServiceCode doesn't exist
  /// in the master list, it is injected so it remains visible and selectable.
  Future<void> fetchHMISPatientTestsWithMaster() async {
    try {
      isLoadingTests.value = true;

      // Run both API calls in parallel for speed
      final results = await Future.wait([
        _registrationService.getHMISPatientTests(hmisPatientId.value),
        _registrationService.fetchTestsByCategory(1),
        _registrationService.fetchTestsByCategory(2),
        _registrationService.fetchTestsByCategory(3),
      ]);

      final hmisResponse = results[0] as Map<String, dynamic>;
      final masterBasicA = results[1] as List<TestModel>;
      final masterBasicB = results[2] as List<TestModel>;
      final masterAdvance = results[3] as List<TestModel>;

      // ── Process master tests first ──────────────────────────────────────────
      final List<TestModel> allMasterBasic = [...masterBasicA, ...masterBasicB];
      final List<TestModel> allMasterAdvance = [...masterAdvance];

      // Build a quick lookup by testId
      final Map<dynamic, TestModel> masterBasicById = {
        for (var t in allMasterBasic) t.testId: t,
      };
      final Map<dynamic, TestModel> masterAdvanceById = {
        for (var t in allMasterAdvance) t.testId: t,
      };

      // ── Process HMIS tests ──────────────────────────────────────────────────
      if (hmisResponse['status'] == 'Success' &&
          hmisResponse['output'] != null) {
        final List<dynamic> outputList = hmisResponse['output'];


        print('hmis outputList: $outputList');



        final List<TestModel> hmisTests = outputList.map((item) {
          return TestModel(
            testId: item['ServiceCode'],
            testName: item['ServiceName'],
            labcategory: _getCategoryName(item['CatCode']),
            srno: 0,
            hmisData: {
              'PatientID': item['PatientID'],
              'PermNo': item['PermNo'],
              'TreatementId': item['TreatementId'],
              'OpdNumber': item['OpdNumber'],
              'VoucherNumber': item['VoucherNumber'],
              'MOBCATCODE': item['MOBCATCODE'],
            },
          );
        }).toList();

        // ── Update patient metadata from first HMIS record ──────────────────
        final firstRecord = outputList.first;
        requisitionDno.value = firstRecord['TreatementId']?.toString() ?? '';
        hmisVoucherNumber.value = firstRecord['VoucherNumber']?.toString() ?? '';

        final List<Map<String, dynamic>> patients =
        List<Map<String, dynamic>>.from(
            patientArray.value['patientArray'] ?? []);
        if (patients.isNotEmpty) {
          patients[0] = {
            ...patients[0],
            'tokenId': firstRecord['OpdNumber']?.toString() ?? '',
            'patCrno': firstRecord['PermNo']?.toString() ?? '',
          };
          patientArray.value = {
            ...patientArray.value,
            'patientArray': patients,
          };
        }

        // ── Inject HMIS tests that are missing from master lists ─────────────
        // A test is "missing" when its ServiceCode isn't in the master lookup.
        // We inject it so it appears in the UI and stays selectable.
        for (final hmisTest in hmisTests) {
          final mobCat = hmisTest.hmisData?['MOBCATCODE'];
          final isBasic = mobCat == 1 || mobCat == 2;
          final isAdvance = mobCat == 3;

          if (isBasic && !masterBasicById.containsKey(hmisTest.testId)) {
            debugPrint(
                '⚠️ HMIS test [${hmisTest.testId}] "${hmisTest.testName}" '
                    'not found in master BASIC list — injecting.');
            allMasterBasic.add(hmisTest);
            masterBasicById[hmisTest.testId] = hmisTest;
          } else if (isAdvance &&
              !masterAdvanceById.containsKey(hmisTest.testId)) {
            debugPrint(
                '⚠️ HMIS test [${hmisTest.testId}] "${hmisTest.testName}" '
                    'not found in master ADVANCE list — injecting.');
            allMasterAdvance.add(hmisTest);
            masterAdvanceById[hmisTest.testId] = hmisTest;
          }
        }

        // ── Assign merged master lists ────────────────────────────────────────
        basicTests.assignAll(allMasterBasic);
        advanceTests.assignAll(allMasterAdvance);

        // ── Auto-select HMIS tests ────────────────────────────────────────────
        // Use the master version if available (preserves srno, etc.)
        // Fall back to the HMIS model if it was injected.
        hmisPreAssignedTestIds.assignAll(hmisTests.map((t) => t.testId));

        final List<TestModel> autoSelected = hmisTests.map((hmisTest) {
          return masterBasicById[hmisTest.testId] ??
              masterAdvanceById[hmisTest.testId] ??
              hmisTest;
        }).toList();

        selectedTests.assignAll(autoSelected);

        debugPrint(
            '✅ Auto-selected ${autoSelected.length} HMIS pre-assigned tests');
        debugPrint(
            '📋 Master basic: ${allMasterBasic.length} | advance: ${allMasterAdvance.length}');
      } else {
        // HMIS fetch failed – still show all master tests, just no auto-select
        SnackBarService.to.showMessage(
          message:
          hmisResponse['message'] ?? 'Failed to load HMIS patient tests',
        );
        basicTests.assignAll(allMasterBasic);
        advanceTests.assignAll(allMasterAdvance);
      }

      _groupTestsByLabCategory();
    } catch (e) {
      SnackBarService.to
          .showMessage(message: 'Failed to load tests: $e');
    } finally {
      isLoadingTests.value = false;
    }
  }

  // Helper to get category name from code
  String _getCategoryName(int? catCode) {
    switch (catCode) {
      case 1:
        return 'Hematology';
      case 2:
        return 'Biochemistry';
      case 3:
        return 'Microbiology';
      default:
        return 'Others';
    }
  }

  Future<void> fetchAllTests() async {
    try {
      isLoadingTests.value = true;
      final basicTestsA = await _registrationService.fetchTestsByCategory(1);
      final basicTestsB = await _registrationService.fetchTestsByCategory(2);
      final advanceTestsList =
      await _registrationService.fetchTestsByCategory(3);

      basicTests.assignAll([...basicTestsA, ...basicTestsB]);
      advanceTests.assignAll(advanceTestsList);
      _groupTestsByLabCategory();
    } catch (e) {
      SnackBarService.to.showMessage(message: 'Failed to load tests: $e');
    } finally {
      isLoadingTests.value = false;
    }
  }

  void _groupTestsByLabCategory() {
    Map<String, List<TestModel>> groupAndSortByCategory(
        List<TestModel> tests) {
      final Map<String, List<TestModel>> grouped = {};
      for (var test in tests) {
        final category = test.labcategory ?? 'Others';
        grouped.putIfAbsent(category, () => []).add(test);
      }
      for (var testList in grouped.values) {
        testList.sort((a, b) => (a.srno ?? 0).compareTo(b.srno ?? 0));
      }
      return grouped;
    }

    basicCategorized.assignAll(groupAndSortByCategory(basicTests));
    advanceCategorized.assignAll(groupAndSortByCategory(advanceTests));
    originalBasicCategorized.value = Map.from(basicCategorized);
    originalAdvanceCategorized.value = Map.from(advanceCategorized);

    expandedCategories
      ..clear()
      ..addAll(basicCategorized.keys)
      ..addAll(advanceCategorized.keys);
  }

  void toggleTestSelection(TestModel test) {
    final isSelected = selectedTests.any((t) => t.testId == test.testId);

    if ([969, 970, 971].contains(test.testId)) {
      if (isSelected) {
        selectedTests.removeWhere((t) => t.testId == test.testId);
        debugPrint('❌ Removed ${test.testId}');
      } else {
        selectedTests.removeWhere((t) => [969, 970, 971].contains(t.testId));
        selectedTests.add(test);
        debugPrint('✅ Added ${test.testId}');
      }
    } else {
      final existingIndex =
      selectedTests.indexWhere((t) => t.testId == test.testId);
      if (existingIndex != -1) {
        selectedTests.removeAt(existingIndex);
        debugPrint('❌ Removed ${test.testId}');
      } else {
        selectedTests.add(test);
        debugPrint('✅ Added ${test.testId}');
      }
    }
  }

  bool isTestSelected(TestModel test) {
    return selectedTests.any((t) => t.testId == test.testId);
  }

  /// Returns true if this test was pre-assigned by HMIS (auto-selected).
  bool isHMISPreAssigned(TestModel test) {
    return hmisPreAssignedTestIds.contains(test.testId);
  }

  void clearAllSelections() {
    selectedTests.clear();
    clearSearch();
  }

  List<TestModel> getSelectedTestsForAPI() {
    return selectedTests;
  }

  void searchTests(String query) {
    searchQuery.value = query.toLowerCase();
    _filterTestsBySearch();
  }

  void clearSearch() {
    searchQuery.value = '';
    searchController.clear();
    searchFocusNode.unfocus();
    basicCategorized.value = Map.from(originalBasicCategorized);
    advanceCategorized.value = Map.from(originalAdvanceCategorized);
    expandedCategories.clear();
  }

  void _filterTestsBySearch() {
    if (searchQuery.value.isEmpty) {
      basicCategorized.value = Map.from(originalBasicCategorized);
      advanceCategorized.value = Map.from(originalAdvanceCategorized);
      return;
    }

    final filteredBasic = <String, List<TestModel>>{};
    for (var category in originalBasicCategorized.keys) {
      final filteredTests = originalBasicCategorized[category]!
          .where((test) =>
      test.testName?.toLowerCase().contains(searchQuery.value) ?? false)
          .toList();
      if (filteredTests.isNotEmpty) {
        filteredBasic[category] = filteredTests;
      }
    }
    basicCategorized.value = filteredBasic;

    final filteredAdvance = <String, List<TestModel>>{};
    for (var category in originalAdvanceCategorized.keys) {
      final filteredTests = originalAdvanceCategorized[category]!
          .where((test) =>
      test.testName?.toLowerCase().contains(searchQuery.value) ?? false)
          .toList();
      if (filteredTests.isNotEmpty) {
        filteredAdvance[category] = filteredTests;
      }
    }
    advanceCategorized.value = filteredAdvance;

    expandedCategories
      ..clear()
      ..addAll(filteredBasic.keys)
      ..addAll(filteredAdvance.keys);
  }

  bool isLabCategoryExpanded(String categoryName) {
    return expandedCategories.contains(categoryName);
  }

  void toggleLabCategoryExpansion(String categoryName) {
    if (expandedCategories.contains(categoryName)) {
      expandedCategories.remove(categoryName);
    } else {
      expandedCategories.add(categoryName);
    }
  }

  void toggleSelectedTestsVisibility() {
    showSelectedTests.value = !showSelectedTests.value;
  }
}



