import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:lifenity_connect/services/snackbar_service.dart';
import 'package:lifenity_connect/services/user_service.dart';

import '../../../auth/model/profile_model.dart';
import '../model/zero_sample_data_model.dart';
import '../service/zero_calendar_service.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';



class ZeroSampleController extends GetxController {
  final ZeroSampleService _service = ZeroSampleService();

  var isLoading = false.obs;
  var errorMessage = ''.obs;
  final DateTime runningMonth = DateTime.now();
  var selectedDate = DateTime.now().obs;
  var zeroSampleDates = <DateTime, ZeroSampleData>{}.obs;
  var remarksData = <RemarkData>[].obs;
  var currentMonth = DateTime.now().obs;
  var userProfile = Rx<ProfileData?>(null);
  final RxString divId = ''.obs;
  final RxString userId = ''.obs;

  final UserService userService = Get.put(UserService());

  @override
  void onInit() {
    super.onInit();
    loadUser();
  }

  void loadUser() async {
    try {
      final userProfileResponse = await userService.getUserProfile();
      userProfile.value = userProfileResponse;
      divId.value = userProfile.value!.divisionId.toString();
      debugPrint('✅ divId set: ${divId.value}');
      userId.value = userProfile.value!.empCode.toString();
      debugPrint('✅ userId set: ${userId.value}');
      loadCalendarData();
    } catch (e) {
      debugPrint('❌ Error loading user: $e');
    }
  }

  void changeMonth(DateTime newMonth) {
    if (newMonth.month > runningMonth.month) {
      return;
    }
    currentMonth.value = newMonth;
    if (selectedDate.value.month != newMonth.month || selectedDate.value.year != newMonth.year) {
      selectedDate.value = DateTime(newMonth.year, newMonth.month, 1);
    }
    loadCalendarData();
  }

  void selectDate(DateTime date) {
    selectedDate.value = date;
    selectedDate.refresh();
    update();
  }

  Future<void> loadCalendarData() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      final monthId = DateFormat('MM').format(currentMonth.value);
      final year = currentMonth.value.year.toString();

      await _loadZeroSampleDates(monthId, year);
      await _loadRemarksData(monthId, year);
    } catch (e) {
      errorMessage.value = 'Failed to load calendar data: Please try again later.';
     SnackBarService.to.showMessage(message: errorMessage.value);
      debugPrint('❌ Error loading calendar data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadZeroSampleDates(String monthId, String year) async {
    final response = await _service.getZeroSampleData(
      monthId: monthId,
      year: year,
      type: 1,
      divId: divId.value,
      userId: userId.value,
    );

    if (response.status == 'Success') {
      zeroSampleDates.clear();
      for (var item in response.output) {
        final data = ZeroSampleData.fromJson(item);
        final date = DateFormat('dd-MMM-yyyy').parse(data.visitDate);
        zeroSampleDates[DateTime(date.year, date.month, date.day)] = data;
      }
      zeroSampleDates.refresh();
    }
  }

  Future<void> _loadRemarksData(String monthId, String year) async {
    final response = await _service.getZeroSampleData(
      monthId: monthId,
      year: year,
      type: 3,
      divId: divId.value,
      userId: userId.value,
    );

    if (response.status == 'Success') {
      remarksData.clear();
      for (var item in response.output) {
        remarksData.add(RemarkData.fromJson(item));
      }
      remarksData.refresh();
    }
  }

  ZeroSampleData? getZeroSampleDataForDate(DateTime date) {
    return zeroSampleDates[DateTime(date.year, date.month, date.day)];
  }

  int getActualZeroSampleCount(DateTime date) {
    final data = getZeroSampleDataForDate(date);
    return data?.zeroSampleCount ?? 0;
  }

  bool hasZeroSamples(DateTime date) {
    return getActualZeroSampleCount(date) > 0;
  }

  int getSamplesCollected(DateTime date) {
    final data = getZeroSampleDataForDate(date);
    if (data == null) return 0;
    return data.totalFacilities - data.zeroSampleCount;
  }

  int getTotalFacilities(DateTime date) {
    final data = getZeroSampleDataForDate(date);
    return data?.totalFacilities ?? 0;
  }

  List<RemarkData> getActiveRemarks() {
    return remarksData.where((remark) => remark.remark > 0).toList();
  }

  String getMostFrequentRemark() {
    if (remarksData.isEmpty) return 'No remarks available';
    final activeRemarks = getActiveRemarks();
    if (activeRemarks.isEmpty) return 'No active remarks';
    activeRemarks.sort((a, b) => (b.remark + b.totalFacilities).compareTo(a.remark + a.totalFacilities));
    return activeRemarks.first.remarkHeader;
  }

  double getSampleCollectionPercentage(DateTime date) {
    final data = getZeroSampleDataForDate(date);
    if (data == null || data.totalFacilities == 0) return 0.0;
    return ((data.totalFacilities - data.zeroSampleCount) / data.totalFacilities) * 100;
  }

  String getCompletionStatus(DateTime date) {
    final percentage = getSampleCollectionPercentage(date);
    if (percentage == 100) return 'Complete';
    if (percentage >= 80) return 'Good';
    if (percentage >= 50) return 'Average';
    return 'Poor';
  }
}
