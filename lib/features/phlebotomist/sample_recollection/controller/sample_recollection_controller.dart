import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_recollection/service/sample_recollection_service.dart';

import '../../../../services/auth_manager.dart';
import '../../../../services/snackbar_service.dart';
import '../../patient_registration/models/facility_list_model.dart';
import '../../patient_registration/service/patient_registration_service.dart';
import '../model/test_recollection_model.dart';
class SampleRecollectionController extends GetxController {
  var isLoading = false.obs;
  var initialLoading = false.obs;
  final RxString empId = ''.obs;

  final RxList<FacilityModel> facilityNames = <FacilityModel>[].obs;
  final RxString facilityInfoError = ''.obs;
  final Rx<FacilityModel?> selectedFacilityName = Rx<FacilityModel?>(null);

  // Date selection
  final Rx<DateTime?> fromDate = Rx<DateTime?>(DateTime.now().subtract(const Duration(days: 1)));
  final Rx<DateTime?> toDate = Rx<DateTime?>(DateTime.now());

  // Tab selection
  final RxInt selectedTab = 0.obs;

  // Original lists
  final RxList<RecollectionTestListUpdated> recollectionPendingList = <RecollectionTestListUpdated>[].obs;
  final RxList<RecollectionTestListUpdated> recollectionAcceptedList = <RecollectionTestListUpdated>[].obs;
  final RxList<RecollectionTestListUpdated> recollectionDeniedList = <RecollectionTestListUpdated>[].obs;

  // Grouped lists (Map of orderId -> List of tests)
  final RxMap<String, List<RecollectionTestListUpdated>> groupedPendingList = <String, List<RecollectionTestListUpdated>>{}.obs;
  final RxMap<String, List<RecollectionTestListUpdated>> groupedAcceptedList = <String, List<RecollectionTestListUpdated>>{}.obs;
  final RxMap<String, List<RecollectionTestListUpdated>> groupedDeniedList = <String, List<RecollectionTestListUpdated>>{}.obs;

  // Filtered grouped lists
  final RxMap<String, List<RecollectionTestListUpdated>> filteredGroupedPendingList = <String, List<RecollectionTestListUpdated>>{}.obs;
  final RxMap<String, List<RecollectionTestListUpdated>> filteredGroupedAcceptedList = <String, List<RecollectionTestListUpdated>>{}.obs;
  final RxMap<String, List<RecollectionTestListUpdated>> filteredGroupedDeniedList = <String, List<RecollectionTestListUpdated>>{}.obs;

  final RxString searchQuery = ''.obs;
  RxBool isSearchExpanded = false.obs;

  // Track expanded cards
  final RxSet<String> expandedCards = <String>{}.obs;

  // Services
  final SampleRecollectionService _service = Get.put(SampleRecollectionService());
  final PatientRegistrationService _registrationService = Get.put(PatientRegistrationService());
  final AuthManager authManager = Get.find<AuthManager>();

  @override
  void onInit() {
    debugPrint('------------------------SampleRecollectionController initialized--------------------');
    super.onInit();
    getUserdata();
  }

  @override
  void onClose() {
    debugPrint('------------------------SampleRecollectionController disposed--------------------------');
    super.onClose();
    clearFilters();
  }

  void getUserdata() {
    authManager.getUserData().then((data) {
      print('📅user data from auth');
      if (data != null) {
        data.forEach((key, value) {
          debugPrint('$key: $value');
        });
        final user = data['user'];
        if (user != null && user.containsKey('EmpCode')) {
          empId.value = user['EmpCode'].toString();
          fetchDropdownData();
          debugPrint('✅ empId set: ${empId.value}');
        } else {
          debugPrint('❌ EmpCode not found in user data');
        }
      } else {
        debugPrint('No user data found');
      }
    }).catchError((err) {
      debugPrint('Error loading user data: $err');
    });
  }

  void fetchDropdownData() async {
    try {
      isLoading.value = true;
      initialLoading.value = true;
      final userId = empId.value;

      final facilities = await _registrationService.getFacilityList(userId);
      facilityNames.assignAll(facilities);
      if (facilityNames.isNotEmpty) {
        selectedFacilityName.value = facilityNames.first;
      }
      await fetchAllRecollectionLists();
    } catch (e) {
      print('Error loading dropdown data: $e');
    } finally {
      isLoading.value = false;
      initialLoading.value = false;
    }
  }

  Future<void> fetchAllRecollectionLists() async {
    if (selectedFacilityName.value == null) {
      facilityInfoError.value = 'Please select a facility';
      return;
    }
    if (fromDate.value == null || toDate.value == null) {
      SnackBarService.to.showMessage(message: 'Please select both from and to dates');
      return;
    }

    try {
      isLoading.value = true;
      facilityInfoError.value = '';
      final facilityId = selectedFacilityName.value?.facilityId ?? '';

      final fromDateStr = DateFormat('yyyy-MM-dd').format(fromDate.value!);
      final toDateStr = DateFormat('yyyy-MM-dd').format(toDate.value!);

      final results = await Future.wait([
        _service.fetchRecollectionDataUpdated(
          formDate: fromDateStr,
          toDate: toDateStr,
          facilityId: facilityId.toString(),
          type: '2', // Pending
        ),
        _service.fetchRecollectionDataUpdated(
          formDate: fromDateStr,
          toDate: toDateStr,
          facilityId: facilityId.toString(),
          type: '1', // Accepted
        ),
        _service.fetchRecollectionDataUpdated(
          formDate: fromDateStr,
          toDate: toDateStr,
          facilityId: facilityId.toString(),
          type: '3', // Denied
        ),
      ]);

      // Assign to original lists
      recollectionPendingList.assignAll(results[0]);
      recollectionAcceptedList.assignAll(results[1]);
      recollectionDeniedList.assignAll(results[2]);

      // Group the lists by orderId
      groupedPendingList.value = groupTestsByOrderId(results[0]);
      groupedAcceptedList.value = groupTestsByOrderId(results[1], useRecollectedBarcode: true);
      groupedDeniedList.value = groupTestsByOrderId(results[2]);

      // Initialize filtered lists
      filteredGroupedPendingList.value = Map.from(groupedPendingList);
      filteredGroupedAcceptedList.value = Map.from(groupedAcceptedList);
      filteredGroupedDeniedList.value = Map.from(groupedDeniedList);

      if (results[0].isEmpty && results[1].isEmpty && results[2].isEmpty) {
        toggleSearchExpansion();
        SnackBarService.to.showMessage(message: 'No tests found for the selected date range');
      }
    } catch (e) {
      SnackBarService.to.showMessage(message: 'Failed to fetch recollection data');
      debugPrint('Error fetching recollection data : $e');
    } finally {
      isLoading.value = false;
    }
  }

  void changeTab(int index) {
    selectedTab.value = index;
    searchQuery.value = '';
    filterReports('');
  }

  Map<String, List<RecollectionTestListUpdated>> getCurrentGroupedList() {
    switch (selectedTab.value) {
      case 0:
        return filteredGroupedPendingList;
      case 1:
        return filteredGroupedAcceptedList;
      case 2:
        return filteredGroupedDeniedList;
      default:
        return filteredGroupedPendingList;
    }
  }

  int getTotalCount() {
    return recollectionPendingList.length +
        recollectionAcceptedList.length +
        recollectionDeniedList.length;
  }

  void filterReports(String query) {
    searchQuery.value = query;

    if (query.isEmpty) {
      filteredGroupedPendingList.value = Map.from(groupedPendingList);
      filteredGroupedAcceptedList.value = Map.from(groupedAcceptedList);
      filteredGroupedDeniedList.value = Map.from(groupedDeniedList);
    } else {
      final searchLower = query.toLowerCase();

      filteredGroupedPendingList.value = _filterGroupedList(groupedPendingList, searchLower);
      filteredGroupedAcceptedList.value = _filterGroupedList(groupedAcceptedList, searchLower);
      filteredGroupedDeniedList.value = _filterGroupedList(groupedDeniedList, searchLower);
    }
  }

  Map<String, List<RecollectionTestListUpdated>> _filterGroupedList(
      Map<String, List<RecollectionTestListUpdated>> groupedList,
      String searchLower) {
    final Map<String, List<RecollectionTestListUpdated>> filtered = {};

    groupedList.forEach((orderId, tests) {
      final firstTest = tests.first;
      final name = firstTest.patientName.toLowerCase();
      final barcode = firstTest.orderId.toLowerCase();
      final newBarcode = (firstTest.recollectedBarcode ?? '').toLowerCase();

      if (name.contains(searchLower) ||
          barcode.contains(searchLower) ||
          newBarcode.contains(searchLower)) {
        filtered[orderId] = tests;
      }
    });

    return filtered;
  }
  Map<String, List<RecollectionTestListUpdated>> groupTestsByOrderId(
      List<RecollectionTestListUpdated> tests, {
        bool useRecollectedBarcode = false,
      }) {
    final Map<String, List<RecollectionTestListUpdated>> grouped = {};

    for (var test in tests) {
      // Decide grouping key
      final key = useRecollectedBarcode
          ? (test.recollectedBarcode?.isNotEmpty == true
          ? test.recollectedBarcode!
          : test.orderId)
          : test.orderId;

      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(test);
    }

    return grouped;
  }

/*  Map<String, List<RecollectionTestListUpdated>> groupTestsByOrderId(
      List<RecollectionTestListUpdated> tests) {
    Map<String, List<RecollectionTestListUpdated>> grouped = {};
    for (var test in tests) {
      if (!grouped.containsKey(test.orderId)) {
        grouped[test.orderId] = [];
      }
      grouped[test.orderId]!.add(test);
    }
    return grouped;
  }*/

  void toggleSearchExpansion() {
    isSearchExpanded.value = !isSearchExpanded.value;
  }

  void toggleCardExpansion(String orderId) {
    if (expandedCards.contains(orderId)) {
      expandedCards.remove(orderId);
    } else {
      expandedCards.add(orderId);
    }
  }

  void clearFilters() {
    selectedFacilityName.value = null;
    fromDate.value = null;
    toDate.value = null;
  }

  RxMap<String, List<RecollectionTestListUpdated>> getCurrentList() {
    switch (selectedTab.value) {
      case 0:
        return groupedAcceptedList ;
      case 1:
        return groupedAcceptedList;
      case 2:
        return groupedDeniedList;
      default:
        return groupedPendingList;
    }
  }
}
/*
class SampleRecollectionController extends GetxController {
  var isLoading = false.obs;
  var initialLoading = false.obs;
  final RxString empId = "".obs;

  final RxList<FacilityModel> facilityNames = <FacilityModel>[].obs;
  final RxString facilityInfoError = "".obs;
  final Rx<FacilityModel?> selectedFacilityName = Rx<FacilityModel?>(null);

  // Date selection
  final Rx<DateTime?> fromDate =
  Rx<DateTime?>(DateTime.now().subtract(Duration(days: 1)));
  final Rx<DateTime?> toDate = Rx<DateTime?>(DateTime.now());

  // Tab selection
  final RxInt selectedTab = 0.obs;

  // Pending list (type = 2)
  final RxList<RecollectionTestListUpdated> recollectionPendingList =
      <RecollectionTestListUpdated>[].obs;
  final RxList<RecollectionTestListUpdated> filteredPendingList =
      <RecollectionTestListUpdated>[].obs;

  // Accepted list (type = 1)
  final RxList<RecollectionTestListUpdated> recollectionAcceptedList =
      <RecollectionTestListUpdated>[].obs;
  final RxList<RecollectionTestListUpdated> filteredAcceptedList =
      <RecollectionTestListUpdated>[].obs;

  // Denied list (type = 3)
  final RxList<RecollectionTestListUpdated> recollectionDeniedList =
      <RecollectionTestListUpdated>[].obs;
  final RxList<RecollectionTestListUpdated> filteredDeniedList =
      <RecollectionTestListUpdated>[].obs;

  final RxString searchQuery = "".obs;
  RxBool isSearchExpanded = false.obs;

  // Services
  final SampleRecollectionService _service =
  Get.put(SampleRecollectionService());
  final PatientRegistrationService _registrationService =
  Get.put(PatientRegistrationService());
  final AuthManager authManager = Get.find<AuthManager>();

  @override
  void onInit() {
    debugPrint("------------------------SampleRecollectionController initialized--------------------");
    super.onInit();
    getUserdata();
  }

  @override
  void onClose() {
    debugPrint("------------------------SampleRecollectionController disposed--------------------------");
    super.onClose();
    clearFilters();
  }

  void getUserdata() {
    authManager.getUserData().then((data) {
      print("📅user data from auth");
      if (data != null) {
        data.forEach((key, value) {
          debugPrint('$key: $value');
        });
        final user = data['user'];
        if (user != null && user.containsKey('EmpCode')) {
          empId.value = user['EmpCode'].toString();
          fetchDropdownData();
          debugPrint('✅ empId set: ${empId.value}');
        } else {
          debugPrint('❌ EmpCode not found in user data');
        }
      } else {
        debugPrint('No user data found');
      }
    }).catchError((err) {
      debugPrint('Error loading user data: $err');
    });
  }

  void fetchDropdownData() async {
    try {
      isLoading.value = true;
      initialLoading.value = true;
      final userId = empId.value;

      final facilities = await _registrationService.getFacilityList(userId);
      facilityNames.assignAll(facilities);
      if (facilityNames.isNotEmpty) {
        selectedFacilityName.value = facilityNames.first;
      }
      await fetchAllRecollectionLists();
    } catch (e) {
      print("Error loading dropdown data: $e");
    } finally {
      isLoading.value = false;
      initialLoading.value = false;
    }
  }

  Future<void> fetchAllRecollectionLists() async {
    // Validation
    if (selectedFacilityName.value == null) {
      facilityInfoError.value = "Please select a facility";
      return;
    }
    if (fromDate.value == null || toDate.value == null) {
      SnackBarService.to.showMessage(
        message: 'Please select both from and to dates',
      );
      return;
    }

    try {
      isLoading.value = true;
      facilityInfoError.value = "";
      final facilityId = selectedFacilityName.value?.facilityId ?? '';

      final fromDateStr = DateFormat('yyyy/MM/dd').format(fromDate.value!);
      final toDateStr = DateFormat('yyyy/MM/dd').format(toDate.value!);

      // Fetch all three lists in parallel
      final results = await Future.wait([
        _service.fetchRecollectionDataUpdated(

          formDate: fromDateStr,
          toDate: toDateStr,
          facilityId: facilityId.toString(),
          type: "2", // Pending
        ),
        _service.fetchRecollectionDataUpdated(

          formDate: fromDateStr,
          toDate: toDateStr,
          facilityId: facilityId.toString(),
          type: "1", // Accepted
        ),
        _service.fetchRecollectionDataUpdated(

          formDate: fromDateStr,
          toDate: toDateStr,
          facilityId: facilityId.toString(),
          type: "3", // Denied
        ),
      ]);

      // Assign results
      recollectionPendingList.assignAll(results[0]);
      filteredPendingList.assignAll(results[0]);

      recollectionAcceptedList.assignAll(results[1]);
      filteredAcceptedList.assignAll(results[1]);

      recollectionDeniedList.assignAll(results[2]);
      filteredDeniedList.assignAll(results[2]);

      // Show message if all lists are empty
      if (results[0].isEmpty && results[1].isEmpty && results[2].isEmpty) {
        toggleSearchExpansion();
        SnackBarService.to.showMessage(
          message: 'No tests found for the selected date range',
        );
      }
    } catch (e) {
      SnackBarService.to.showMessage(
        message: 'Failed to fetch recollection data',
      );
      debugPrint("Error fetching recollection data : $e");
    } finally {
      isLoading.value = false;
    }
  }

  void changeTab(int index) {
    selectedTab.value = index;
    // Clear search when changing tabs
    searchQuery.value = "";
    filterReports("");
  }

  List<RecollectionTestListUpdated> getCurrentList() {
    switch (selectedTab.value) {
      case 0:
        return filteredPendingList;
      case 1:
        return filteredAcceptedList;
      case 2:
        return filteredDeniedList;
      default:
        return filteredPendingList;
    }
  }

  int getTotalCount() {
    return recollectionPendingList.length +
        recollectionAcceptedList.length +
        recollectionDeniedList.length;
  }

  void filterReports(String query) {
    searchQuery.value = query;

    if (query.isEmpty) {
      // Reset to original lists
      filteredPendingList.assignAll(recollectionPendingList);
      filteredAcceptedList.assignAll(recollectionAcceptedList);
      filteredDeniedList.assignAll(recollectionDeniedList);
    } else {
      final searchLower = query.toLowerCase();

      // Filter each list based on search query
      filteredPendingList.assignAll(
        recollectionPendingList.where((test) {
          final name = test.patientName.toLowerCase();
          final barcode = test.orderId.toLowerCase();
          return name.contains(searchLower) || barcode.contains(searchLower);
        }).toList(),
      );

      filteredAcceptedList.assignAll(
        recollectionAcceptedList.where((test) {
          final name = test.patientName.toLowerCase();
          final barcode = test.orderId.toLowerCase();
          final newBarcode = (test.recollectedBarcode ?? '').toLowerCase();
          return name.contains(searchLower) ||
              barcode.contains(searchLower) ||
              newBarcode.contains(searchLower);
        }).toList(),
      );

      filteredDeniedList.assignAll(
        recollectionDeniedList.where((test) {
          final name = test.patientName.toLowerCase();
          final barcode = test.orderId.toLowerCase();
          return name.contains(searchLower) || barcode.contains(searchLower);
        }).toList(),
      );
    }
  }

  Map<String, List<RecollectionTestListUpdated>> groupTestsByOrderId(
      List<RecollectionTestListUpdated> tests) {
    Map<String, List<RecollectionTestListUpdated>> grouped = {};
    for (var test in tests) {
      if (!grouped.containsKey(test.orderId)) {
        grouped[test.orderId] = [];
      }
      grouped[test.orderId]!.add(test);
    }
    return grouped;
  }

  void toggleSearchExpansion() {
    isSearchExpanded.value = !isSearchExpanded.value;
  }

  void clearFilters() {
    selectedFacilityName.value = null;
    fromDate.value = null;
    toDate.value = null;
  }

  Set<String> expandedCards = <String>{};

  void toggleCardExpansion(String orderId) {
    if (expandedCards.contains(orderId)) {
      expandedCards.remove(orderId);
    } else {
      expandedCards.add(orderId);
    }
    update();
  }
}*/
