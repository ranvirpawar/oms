import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/features/auth/model/login_response_model.dart';
import 'package:lifenity_connect/features/lab_technician/sample_accept/view/accept_in_lab_view.dart';
import 'package:lifenity_connect/services/snackbar_service.dart';

import '../../../../services/user_service.dart';
import '../../../../theme/app_colors.dart';
import '../model/resource_model.dart';
import '../service/sample_accept_service.dart';

// Updated SampleAcceptController
class SampleAcceptController extends GetxController {
  final SampleAcceptService _service = SampleAcceptService();
  final UserService userService = UserService();

  // Observable variables
  var selectedDate = DateTime.now().obs;
  var userData = Rxn<UserModel>();
  var empId = ''.obs;
  var labCode = ''.obs;
  var selectedDesignationId = 7.obs; // Default to Runner Boy
  var resourcesList = <ResourcesData>[].obs;
  var isLoading = false.obs;
  var searchQuery = ''.obs;
  var originalList = <ResourcesData>[].obs;

  final List<Map<String, String>> designations = [
    {'id': '18', 'name': 'Additional Phlebotomist'},
    {'id': '7', 'name': 'Runner Boy'},
    {'id': '4', 'name': 'Phlebotomist'},
    {'id': '8', 'name': 'Phlebo Runner Boy'},
  ];

  @override
  void onInit() {
    super.onInit();
    loadUser();
  }

  void onSearchChanged(String value) {
    if (value.isEmpty) {
      resourcesList.assignAll(originalList);
    } else {
      resourcesList.assignAll(
        originalList
            .where((r) => r.name.toLowerCase().contains(value.toLowerCase())),
      );
    }
  }

  void loadUser() async {
    try {
      final user = await userService.getUser();
      if (user != null) {
        userData.value = user;
      } else {
        debugPrint('❌ Failed to load user data');
      }

      final userProfile = await userService.getUserProfile();
      empId.value = userProfile?.empCode.toString() ?? '';
      labCode.value = userProfile?.labCode.toString() ?? '';

      // Load initial data
      if (labCode.value.isNotEmpty) {
        await loadResourcesData();
      }
    } catch (e) {
      debugPrint('❌ Error loading user: $e');
    }
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate.value) {
      selectedDate.value = picked;
      await loadResourcesData();
    }
  }

  void onDesignationChanged(String? newValue) {
    if (newValue != null) {
      selectedDesignationId.value = int.parse(newValue);
      loadResourcesData();
    }
  }

  Future<void> loadResourcesData() async {
    if (labCode.value.isEmpty) return;

    isLoading.value = true;
    try {
      final dateString = selectedDate.value.toString().split(' ')[0];
      final resources = await _service.getResourcesNamesAndVisitData(
        labCode.value,
        dateString,
        selectedDesignationId.value,
      );
      resourcesList.assignAll(resources);
      originalList.assignAll(resources); // 🔥 THIS WAS MISSING
    } catch (e) {
      debugPrint('❌ Error loading resources: $e');
      Get.snackbar(
        'Error',
        'Failed to load resources data',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withOpacity(0.7),
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void onResourceTap(ResourcesData resource) {
    if (resource.visitedFacility == 0) {
      SnackBarService.to.showMessage(
          message: 'No data available acceptance',
          duration: const Duration(seconds: 1));
    } else {
      Get.to(() => AcceptInLabView(
            resource: resource,
            selectedDate: selectedDate.value,
            labCode: labCode.value,
            labTechnicianId: empId.value,
          ));
    }
  }

  String get selectedDesignationName {
    final designation = designations.firstWhere(
      (item) => item['id'] == selectedDesignationId.value.toString(),
      orElse: () => designations[1], // Default to Runner Boy
    );
    return designation['name'] ?? 'Runner Boy';
  }
}
