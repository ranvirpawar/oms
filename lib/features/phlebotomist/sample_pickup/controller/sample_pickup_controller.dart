import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/features/auth/model/login_response_model.dart';

import '../../../../services/auth_manager.dart';
import '../../../../services/user_service.dart';
import '../../../../theme/app_colors.dart';
import '../model/work_item_model.dart';
import '../service/sample_pickup_service.dart';

// sample_pickup_controller.dart
class SamplePickupController extends GetxController {
  var userData = Rx<UserModel?>(null);
  final AuthManager authManager = Get.put(AuthManager());
  final SamplePickupService _service = SamplePickupService();

  var empId = ''.obs;
  var centerId = ''.obs;
  var selectedDate = DateTime.now().obs;

  var isLoading = false.obs;

  var showFloatingButton = false.obs;

  final workList = <WorkItem>[].obs;
  final selectedFacility = Rxn<WorkItem>();
  final UserService userService = Get.put(UserService());

  @override
  void onInit() {
    loadUser();
    super.onInit();
  }

  void loadUser() async {
    final user = await userService.getUser();

    if (user != null) {
      userData.value = user;
      userData.value = user;
      empId.value = userData.value!.empCode.toString();
      submitToLabList();
    } else {
      debugPrint('❌ Failed to load user data');
    }
  }

  // list of api to get facility of user

  // general list of sample before submit to lab
  Future<void> submitToLabList() async {
    if (empId.value.isEmpty) {
      debugPrint('❌ Cannot load daily work: empId is empty');
      return;
    }

    try {
      isLoading.value = true;

      // Format date as YYYY-MM-DD
      final dateString = selectedDate.value.toString().split(' ')[0];
      debugPrint(
          '🔍 Fetching daily work for: ${empId.value}, Date: $dateString');

      final List<WorkItem> response =
          await _service.getDailyWorkList(empId.value, dateString, 1);
      workList.value = response;

      debugPrint('📡 API Response: $response');
    } catch (e) {
      debugPrint('❌ Error loading daily work: $e');
      workList.value = [];

      // Show error snackbar to user
      Get.snackbar(
        'Error',
        'Failed to load daily work list',
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void selectFacility(dynamic facility) {
    selectedFacility.value = facility;
    showFloatingButton.value = true;
  }

  void deselectFacility() {
    selectedFacility.value = null;
    showFloatingButton.value = false;
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate.value) {
      selectedDate.value = picked;
      await submitToLabList();
    }
  }

  void submitToLab() {
    if (selectedFacility.value != null) {
      // Implement submit to lab functionality
      Get.snackbar(
        'Success',
        'Sample submitted to lab successfully',
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
      );
    }
  }
}
