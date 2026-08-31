// lib/features/team_lead/test_analysis/controller/test_analysis_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../auth/model/profile_model.dart';
import '../model/test_analysis_model.dart';
import '../service/summary_service.dart';
import '../../../../services/user_service.dart';

class TestAnalysisController extends GetxController {
  var isLoading = true.obs;
  var testAnalysisList = <TestAnalysisModel>[].obs;
  final summaryService = Get.put(SummaryService());
  var userData = Rxn<ProfileData>();
  final UserService userService = UserService();

  @override
  void onInit() {
    super.onInit();
    loadUser();
  }

  void loadUser() async {
    try {
      final userProfile = await userService.getUserProfile();
      userData.value = userProfile;
      // debugPrint("TestAnalysis Controller: ${userData.value.toString()}");
      fetchData();
    } catch (e) {
      debugPrint('❌ Error loading user: $e');
    }
  }

  Future<void> fetchData() async {
    isLoading(true);

    testAnalysisList.value = await summaryService.fetchTestAnalysis(
      drill:'0',
      divId: /*userData.value?.divisionId ??*/ 0,
      distLgdCode: /*userData.value?.distLgdCode ??*/ 0,
      labCode: /*userData.value?.labCode ??*/ 0,
      facilityCode: /*userData.value?.facilityCode ??*/ 0,
      // fTypeId: 0,
      testCategoryId: 0,
      serviceCode: 0,
      fTypeShort: 0,
    ) ?? [];

    debugPrint('Test Analysis Data: ${testAnalysisList.length} items loaded');

    isLoading(false);
  }

  Future<void> refreshData() async {
    await fetchData();
  }

  // Get current month data
  TestAnalysisModel? get currentMonthData {
    try {
      return testAnalysisList.firstWhere(
            (item) => item.summaryType.toUpperCase().contains('CURRENT MONTH'),
      );
    } catch (e) {
      return null;
    }
  }

  // Get 3 months average data
  TestAnalysisModel? get threeMonthsAvgData {
    try {
      return testAnalysisList.firstWhere(
            (item) => item.summaryType.toUpperCase().contains('AVG LAST 3 MONTH'),
      );
    } catch (e) {
      return null;
    }
  }
}