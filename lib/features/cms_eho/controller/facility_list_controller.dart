import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../services/user_service.dart';
import '../../auth/model/profile_model.dart';
import '../model/facility_type_model.dart';
import '../service/facility_type_service.dart';


class FacilityListController extends GetxController {
  var isLoading = true.obs;
  var facilities = <FacilityModel>[].obs;
  var filteredFacilities = <FacilityModel>[].obs;
  var searchQuery = ''.obs;

  late FacilityTypeModel facilityType;
  late DateTime fromDate;
  late DateTime toDate;

  final facilityTypeService = FacilityTypeService();
  var userData = Rxn<ProfileData>();
  final UserService userService = UserService();

  // Sorting
  var sortBy = 'name'.obs; // name, patients, tests
  var isAscending = true.obs;

  void initialize(FacilityTypeModel type, DateTime from, DateTime to) {
    facilityType = type;
    fromDate = from;
    toDate = to;
  }

  @override
  void onInit() {
    super.onInit();
    loadUser();

    // Listen to search query changes
    ever(searchQuery, (_) => filterFacilities());
    ever(sortBy, (_) => filterFacilities());
    ever(isAscending, (_) => filterFacilities());
  }

  void loadUser() async {
    try {
      final userProfile = await userService.getUserProfile();
      userData.value = userProfile;
      debugPrint('Controller: ${userData.value?.toJson().toString()}');
      fetchFacilities();
    } catch (e) {
      debugPrint('❌ Error loading user: $e');
      isLoading(false);
    }
  }

  Future<void> fetchFacilities() async {
    if (userData.value == null) return;

    isLoading(true);
    final dateFormat = DateFormat('yyyy-MM-dd');

    final result = await facilityTypeService.fetchFacilities(
      fromDate: dateFormat.format(fromDate),
      toDate: dateFormat.format(toDate),
      ftypeId: facilityType.ftypeId,
      desgId: userData.value!.desgId,
    );

    if (result != null) {
      facilities.value = result;
      filterFacilities();
    } else {
      facilities.clear();
      filteredFacilities.clear();
    }

    isLoading(false);
  }

  void filterFacilities() {
    var filtered = facilities.toList();

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered
          .where((facility) =>
          facility.facilityName.toLowerCase().contains(searchQuery.value.toLowerCase()))
          .toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      int comparison = 0;
      switch (sortBy.value) {
        case 'name':
          comparison = a.facilityName.compareTo(b.facilityName);
          break;
        case 'patients':
          comparison = a.patientCount.compareTo(b.patientCount);
          break;
        case 'tests':
          comparison = a.testCount.compareTo(b.testCount);
          break;
      }
      return isAscending.value ? comparison : -comparison;
    });

    filteredFacilities.value = filtered;
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void updateSorting(String newSortBy) {
    if (sortBy.value == newSortBy) {
      isAscending.value = !isAscending.value;
    } else {
      sortBy.value = newSortBy;
      isAscending.value = true;
    }
  }

  Future<void> selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2017),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: fromDate, end: toDate),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      fromDate = picked.start;
      toDate = picked.end;
      fetchFacilities();
    }
  }

  String get dateRangeText {
    final format = DateFormat('MMM dd, yyyy');
    return '${format.format(fromDate)} - ${format.format(toDate)}';
  }

  Future<void> refreshData() async {
    await fetchFacilities();
  }
}
