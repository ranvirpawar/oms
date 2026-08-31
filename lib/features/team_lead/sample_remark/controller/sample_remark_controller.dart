import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/features/team_lead/sample_remark/model/sample_remark_model.dart';
import 'package:lifenity_connect/services/auth_manager.dart';
import 'package:lifenity_connect/services/user_service.dart';
import 'package:lifenity_connect/utils/helper_functions/helper_methods.dart';

import '../../../../services/snackbar_service.dart';
import '../../../auth/model/profile_model.dart';
import '../../../phlebotomist/patient_registration/models/facility_list_model.dart';
import '../../../phlebotomist/patient_registration/service/patient_registration_service.dart';
import '../model/facilityRemarkModel.dart';
import '../service/sample_remark_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SampleRemarkController extends GetxController {
  var isLoading = false.obs;
  var isSubmitting = false.obs;

  final RxString empId = ''.obs;
  final RxString labCode = ''.obs;
  final RxString facilityCode = ''.obs;
  final RxString desgId = ''.obs;

  final Rx<DateTime?> selectedDate = Rx<DateTime?>(
      DateTime.now().subtract(const Duration(days: 1)));

  final RxString selectedSampleRemark = ''.obs;
  final RxInt selectedSampleRemarkId = 0.obs;

  final RxList<SampleRemarkModel> remarks = <SampleRemarkModel>[].obs;

  final RxList<FacilityModel> facilityNames = <FacilityModel>[].obs;
  final RxString facilityInfoError = ''.obs;
  final Rx<FacilityModel?> selectedFacilityName = Rx<FacilityModel?>(null);

  final Rx<FacilityRemarkModel?> currentFacilityData = Rx<FacilityRemarkModel?>(null);
  final RxBool dataFetched = false.obs;
  final RxBool showReasonDropdown = false.obs;
  final RxBool showSubmitButton = false.obs;
  var userProfile = Rx<ProfileData?>(null);
  final AuthManager authManager = Get.find<AuthManager>();
  final PatientRegistrationService _registrationService = Get.put(PatientRegistrationService());
  final SampleRemarkService _service = Get.put(SampleRemarkService());
  final UserService userService = Get.put(UserService());


  @override
  void onInit() {
    super.onInit();
    getUserdata();
    loadUser();
    fetchSampleRemarkList();
  }
  void loadUser() async {
    try {

      final userProfileResponse = await userService.getUserProfile();
      userProfile.value = userProfileResponse;
      desgId.value = userProfile.value!.desgId.toString();
      debugPrint('✅ desgId set: ${desgId.value}');
    } catch (e) {
      debugPrint('❌ Error loading user: $e');
    }
  }
  void getUserdata() {
    authManager.getUserData().then((data) {
      kPrint('📅user data from auth');
      if (data != null) {
        data.forEach((key, value) {
          debugPrint('$key: $value');
        });
        final user = data['user'];
        if (user != null && user.containsKey('EmpCode')) {
          empId.value = user['EmpCode'].toString();
          desgId.value = user['DesgId']?.toString() ?? '';
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

      final userId = empId.value;

      final facilities = await _registrationService.getFacilityList(userId);
      facilityNames.assignAll(facilities);
      if (facilityNames.isNotEmpty) {
        selectedFacilityName.value = facilityNames.first;
        labCode.value = selectedFacilityName.value!.centerId.toString();
        await fetchDataForSampleRemark();
      }
    } catch (e) {
      kPrint('Error loading dropdown data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void selectDate(DateTime date) {
    selectedDate.value = date;
    if (selectedFacilityName.value != null) {
      fetchDataForSampleRemark();
    }
  }

  Future<void> fetchDataForSampleRemark() async {
    // Validation
    if (selectedFacilityName.value == null) {
      facilityInfoError.value = 'Please select a facility';
      return;
    }
    if (selectedDate.value == null) {
      SnackBarService.to.showMessage(
        message: 'Please select a date',
      );
      return;
    }

    try {
      isLoading.value = true;
      facilityInfoError.value = '';
      dataFetched.value = false;
      showReasonDropdown.value = false;
      showSubmitButton.value = false;
      currentFacilityData.value = null;
      selectedSampleRemark.value = ''; // Reset remark
      selectedSampleRemarkId.value = 0; // Reset remark ID

      final facilityId = selectedFacilityName.value?.facilityId.toString() ?? '';
      final labCodeValue = selectedFacilityName.value?.centerId.toString() ?? '';
      final selectedDateFormatted = DateFormat('yyyy/MM/dd').format(selectedDate.value!);

      final response = await _service.fetchDataForSampleRemark(
        labCodeValue,
        facilityId,
        selectedDateFormatted,
      );

      dataFetched.value = true;

      if (response.isNotEmpty) {
        // Data found - this means no samples were recorded (count = 0)
        currentFacilityData.value = response.first;

        if (currentFacilityData.value!.count == 0) {
          showReasonDropdown.value = true; // Show dropdown regardless of existing remark
          if (currentFacilityData.value!.remarByPhlebO.isNotEmpty) {
            // Pre-select the existing remark
            final existingRemark = remarks.firstWhere(
                  (remark) => remark.remark == currentFacilityData.value!.remarByPhlebO,
              orElse: () => SampleRemarkModel(remark: '', remarkId: 0),
            );
            if (existingRemark.remarkId != 0) {
              selectedSampleRemark.value = existingRemark.remark;
              selectedSampleRemarkId.value = existingRemark.remarkId;
              showSubmitButton.value = true; // Show submit button since a remark is selected
            }
          }
        }
      } else {
        // Empty response means samples were collected for that day
        currentFacilityData.value = null;
        showReasonDropdown.value = false;
      }
    } catch (e) {
      SnackBarService.to.showMessage(
        message: 'Failed to fetch sample remark data',
      );
      debugPrint('Error fetching sample remark data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchSampleRemarkList() async {
    try {
      final response = await _service.fetchSampleRemarkList();
      if (response.isNotEmpty) {
        remarks.assignAll(response);
      }
    } catch (e) {
      debugPrint('Error fetching sample remark list: $e');
    }
  }

  // Listen to changes in selected remark to show/hide submit button
  void onRemarkSelected() {
    showSubmitButton.value = selectedSampleRemark.value.isNotEmpty &&
        selectedSampleRemarkId.value > 0;
  }

  Future<void> submitZeroRemark() async {
    if (selectedSampleRemarkId.value == 0 ||
        selectedFacilityName.value == null ||
        selectedDate.value == null) {
      SnackBarService.to.showMessage(
        message: 'Please fill all required fields',
      );
      return;
    }
    if (currentFacilityData.value?.remarByPhlebO == selectedSampleRemark.value) {
      SnackBarService.to.showMessage(
        message: 'This remark is already set for the selected date and facility',
      );
      return;
    }

    try {
      isSubmitting.value = true;

      final centerId = selectedFacilityName.value!.facilityId.toString();
      final dateFormatted = DateFormat('yyyy-MM-dd').format(selectedDate.value!);
      final userId = empId.value;
      final createdBy = empId.value;
      final desgIdValue = desgId.value;
      final remark = selectedSampleRemark.value;
      final remarkId = selectedSampleRemarkId.value.toString();

      final success = await _service.addZeroRemark(
        centerId: centerId,
        count: '0',
        date: dateFormatted,
        userId: userId,
        createdBy: createdBy,
        desgId: desgIdValue,
        remark: remark,
        remarkId: remarkId,
      );

      if (success) {
        SnackBarService.to.showMessage(
          message: 'Remark submitted successfully',

        );

        // Reset form
        selectedSampleRemark.value = '';
        selectedSampleRemarkId.value = 0;
        showReasonDropdown.value = false;
        showSubmitButton.value = false;

        // Refresh data
        await fetchDataForSampleRemark();
      } else {
        SnackBarService.to.showMessage(
          message: 'Failed to submit remark',
        );
      }
    } catch (e) {
      SnackBarService.to.showMessage(
        message: 'Error submitting remark: $e',
      );
      debugPrint('Error submitting zero remark: $e');
    } finally {
      isSubmitting.value = false;
    }
  }

  // Update the remark selection to trigger submit button visibility
  void updateRemarkSelection(String remarkName, int remarkId) {
    selectedSampleRemark.value = remarkName;
    selectedSampleRemarkId.value = remarkId;
    showSubmitButton.value = remarkName.isNotEmpty && remarkId > 0; // Ensure button visibility
  }
}

