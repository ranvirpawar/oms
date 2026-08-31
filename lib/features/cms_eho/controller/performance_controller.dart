// lib/features/team_lead/performance_dashboard/controller/performance_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../auth/model/profile_model.dart';
import '../model/pending_test_model.dart';
import '../model/test_type_model.dart';
import '../service/summary_service.dart';
import '../../../../services/user_service.dart';

class PerformanceController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;

  var isLoading = true.obs;
  var pendingPatientList = <PendingPatientModel>[].obs;
  var testTypeList = <TestTypeModel>[].obs;

  final summaryService = Get.put(SummaryService());
  var userData = Rxn<ProfileData>();
  final UserService userService = UserService();

  // Date range
  var fromDate = Rx<DateTime>(DateTime.now().subtract(const Duration(days: 7)));
  var toDate = Rx<DateTime>(DateTime.now());

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    loadUser();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  void loadUser() async {
    try {
      final userProfile = await userService.getUserProfile();
      userData.value = userProfile;
      // debugPrint("Performance Controller: ${userData.value.toString()}");
      fetchData();
    } catch (e) {
      debugPrint('❌ Error loading user: $e');
    }
  }

  Future<void> fetchData() async {
    isLoading(true);

    final dateFormat = DateFormat('yyyy/MM/dd');
    final fromDateFormatted = dateFormat.format(fromDate.value);
    final toDateFormatted = dateFormat.format(toDate.value);

    // Fetch pending patients data
    pendingPatientList.value = await summaryService.fetchPendingPatients(
      fromDate: fromDateFormatted,
      toDate: toDateFormatted,
      distLgdCode: /*userData.value?.distLgdCode ??*/ 0,
      divId: /*userData.value?.divisionId ??*/ 0,
      labCode: /*userData.value?.labCode ??*/ 0,
      facilityCode: /*userData.value?.facilityCode ??*/ 0,
    ) ?? [];

    // Fetch test type data
    testTypeList.value = await summaryService.fetchTestTypeData(
      fromDate: fromDateFormatted,
      toDate: toDateFormatted,
      labCode: /*userData.value?.labCode ??*/ 0,
    ) ?? [];

    debugPrint('Pending Patients: ${pendingPatientList.length} items loaded');
    debugPrint('Test Types: ${testTypeList.length} items loaded');

    isLoading(false);
  }

  Future<void> refreshData() async {
    await fetchData();
  }

  Future<void> selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: fromDate.value,
        end: toDate.value,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6366F1),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      fromDate.value = picked.start;
      toDate.value = picked.end;
      await fetchData();
    }
  }

  // Get formatted date range string
  String get dateRangeText {
    final format = DateFormat('dd MMM yyyy');
    return '${format.format(fromDate.value)} - ${format.format(toDate.value)}';
  }

  // Get single lab data (for Lower Parel)
  PendingPatientModel? get singleLabData {
    if (pendingPatientList.isNotEmpty) {
      return pendingPatientList.first;
    }
    return null;
  }

  // Get single lab test type data
  TestTypeModel? get singleLabTestType {
    if (testTypeList.isNotEmpty) {
      return testTypeList.first;
    }
    return null;
  }
}