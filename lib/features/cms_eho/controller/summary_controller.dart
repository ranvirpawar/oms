import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/features/auth/model/profile_model.dart';

import '../../../../services/user_service.dart';
import '../model/summary_model.dart';
import '../service/summary_service.dart';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class SummaryController extends GetxController {
  var isLoading = true.obs;
  var summary = Rx<SummaryModel?>(null);
  var details = Rx<Map<String, dynamic>?>(null);
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
      debugPrint('Controller: ${userData.value?.toJson().toString()}');

      fetchData();
    } catch (e) {
      debugPrint('❌ Error loading user: $e');
    }
  }


  Future<void> fetchData() async {
    isLoading(true);

    // Get today's date and format it for the API
    final now = DateTime.now();
    final dateFormat = DateFormat('MM/dd/yyyy');
    final todayFormatted = dateFormat.format(now);


    final dateFrom = '03/20/2017';
    final dateTo = todayFormatted;

    summary.value = await summaryService.fetchSummary(
      dateFrom: dateFrom,
      dateTo: dateTo,
      distLgdCode: userData.value!.distLgdCode,
      labCode: userData.value!.labCode,
      divId: userData.value!.divisionId,
      facilityCode: 0,
      designationId: userData.value!.desgId,
    );


    details.value = await summaryService.fetchDetails(
      dateFrom: dateFrom,
      dateTo: dateTo,
      distLgdCode: userData.value!.distLgdCode,
      labCode: userData.value!.labCode,
      divId: userData.value!.divisionId,
      facilityCode: 0,
     /* distLgdCode: 0,
      labCode: 0,
      divId: 0,
      facilityCode: 0,*/
      designationId: userData.value!.desgId,
    );
    debugPrint('Controller: ${details.value?.toString()}');

    isLoading(false);
  }

  // Method to refresh data with custom date range if needed
  Future<void> refreshData({String? customDateFrom, String? customDateTo}) async {
    isLoading(true);

    final now = DateTime.now();
    final dateFormat = DateFormat('MM/dd/yyyy');
    final todayFormatted = dateFormat.format(now);

    final dateFrom = customDateFrom ?? todayFormatted;
    final dateTo = customDateTo ?? todayFormatted;

    summary.value = await summaryService.fetchSummary(
      dateFrom: dateFrom,
      dateTo: dateTo,
      distLgdCode: 0,
      labCode: 0,
      divId: userData.value!.divisionId,
      facilityCode: 0,
      designationId: userData.value!.desgId,
    );

    details.value = await summaryService.fetchDetails(
      dateFrom: dateFrom,
      dateTo: dateTo,
      distLgdCode: 0,
      labCode: 0,
      divId: userData.value!.divisionId,
      facilityCode: 0,
      designationId: userData.value!.desgId,
    );

    isLoading(false);
  }
}