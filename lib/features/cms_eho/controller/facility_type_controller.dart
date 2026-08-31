import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../services/user_service.dart';
import '../../auth/model/profile_model.dart';
import '../model/facility_type_model.dart';
import '../service/facility_type_service.dart';

class FacilityTypeController extends GetxController {
  var isLoading = true.obs;
  var facilityTypes = <FacilityTypeModel>[].obs;
  var filteredFacilityTypes = <FacilityTypeModel>[].obs;
  var searchQuery = ''.obs;
  
  var fromDate = Rx<DateTime>(DateTime.now().subtract(const Duration(days: 30)));
  var toDate = Rx<DateTime>(DateTime.now());
  
  final facilityTypeService = FacilityTypeService();
  var userData = Rxn<ProfileData>();
  final UserService userService = UserService();

  @override
  void onInit() {
    super.onInit();
    loadUser();
    
    // Listen to search query changes
    ever(searchQuery, (_) => filterFacilityTypes());
  }

  void loadUser() async {
    try {
      final userProfile = await userService.getUserProfile();
      userData.value = userProfile;
      debugPrint('Controller: ${userData.value?.toJson().toString()}');
      fetchFacilityTypes();
    } catch (e) {
      debugPrint('❌ Error loading user: $e');
      isLoading(false);
    }
  }

  Future<void> fetchFacilityTypes() async {
    if (userData.value == null) return;
    
    isLoading(true);
    final dateFormat = DateFormat('yyyy-MM-dd');
    
    final result = await facilityTypeService.fetchFacilityTypes(
      fromDate: dateFormat.format(fromDate.value),
      toDate: dateFormat.format(toDate.value),
      ftype: 0,
      desgId: userData.value!.desgId,
    );

    if (result != null) {
      facilityTypes.value = result;
      filterFacilityTypes();
    } else {
      facilityTypes.clear();
      filteredFacilityTypes.clear();
    }
    
    isLoading(false);
  }

  void filterFacilityTypes() {
    if (searchQuery.value.isEmpty) {
      filteredFacilityTypes.value = facilityTypes;
    } else {
      filteredFacilityTypes.value = facilityTypes
          .where((type) => type.fType.toLowerCase().contains(searchQuery.value.toLowerCase()))
          .toList();
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  Future<void> selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2017),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: fromDate.value, end: toDate.value),
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
      fromDate.value = picked.start;
      toDate.value = picked.end;
      fetchFacilityTypes();
    }
  }

  String get dateRangeText {
    final format = DateFormat('MMM dd, yyyy');
    return '${format.format(fromDate.value)} - ${format.format(toDate.value)}';
  }

  Future<void> refreshData() async {
    await fetchFacilityTypes();
  }
}
