import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import 'package:intl/intl.dart';
import 'package:lifenity_connect/features/auth/model/login_response_model.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_pickup/service/sample_pickup_service.dart';
import 'package:lifenity_connect/services/snackbar_service.dart';
import 'package:lifenity_connect/services/user_service.dart';
import '../../../../network/api_client.dart';
import '../../../../network/app_urls.dart';
import '../../../../theme/app_colors.dart';
import '../../../../utils/helper_functions/helper_methods.dart';
import '../model/phlebo_sample_pickup.dart';
import 'package:signature/signature.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../model/work_item_model.dart';

class SamplePickUpEntryViewController extends GetxController
    with GetSingleTickerProviderStateMixin {
  UserService userService = Get.put(UserService());
  SamplePickupService samplePickupService = Get.put(SamplePickupService());
  final APIClient apiClient = Get.find<APIClient>();

  var userData = Rx<UserModel?>(null);
  var selectedDate = DateTime.now().obs;
  var facilityPickupList = <PhleboSamplePickup>[].obs;
  var selectedFacility = Rxn<PhleboSamplePickup>();
  final workList = <WorkItem>[].obs;
  var selectedLabFacilities = <WorkItem>[].obs;
  RxBool isLoading = false.obs;

  // Tab controller
  late TabController tabController;
  var currentTabIndex = 0.obs;
  var empId = ''.obs;
  var labCode = ''.obs;

  // Text controllers
  TextEditingController trfRController = TextEditingController();
  TextEditingController tubeCountRController = TextEditingController();
  TextEditingController remarkController = TextEditingController();

  // Signature controller
  final SignatureController signatureController = SignatureController(
    penStrokeWidth: 5,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  @override
  void onInit() {
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(() {
      if (!tabController.indexIsChanging) {
        // ensures change is complete
        currentTabIndex.value = tabController.index;

        if (currentTabIndex.value == 0) {
          // Going to Pickup tab — clear lab selection
          selectedLabFacilities.clear();
          selectedFacility.value = null; // also clear single facility
          trfRController.clear();
          tubeCountRController.clear();
        } else if (currentTabIndex.value == 1) {
          // Going to Lab tab — clear pickup selection
          selectedFacility.value = null;
          trfRController.clear();
          tubeCountRController.clear();
          getSubmitToLabFacilityData();
        }
      }
    });

    loadUser();
    super.onInit();
  }

  @override
  void onClose() {
    tabController.dispose();
    signatureController.dispose();
    trfRController.dispose();
    tubeCountRController.dispose();
    remarkController.dispose();
    super.onClose();
  }

  void loadUser() async {
    final user = await userService.getUser();
    if (user != null) {
      userData.value = user;
    } else {
      debugPrint('❌ Failed to load user data');
    }
    final userProfile = await userService.getUserProfile();
    empId.value = userProfile?.empCode.toString() ?? '';
    labCode.value = userProfile?.labCode.toString() ?? '';

    getFacilityWiseDataForPickup();
  }

  void selectFacility(PhleboSamplePickup facility) {
    selectedFacility.value = facility;
    trfRController.text = facility.trfP?.toString() ?? '';
    tubeCountRController.text = facility.sampleCount?.toString() ?? '';
  }

  void toggleLabFacilitySelection(WorkItem facility) {
    // haptic feedback
    HapticFeedback.lightImpact();

    if (selectedLabFacilities.contains(facility)) {
      selectedLabFacilities.remove(facility);
    } else {
      selectedLabFacilities.add(facility);
    }
  }

  bool isLabFacilitySelected(WorkItem facility) {
    return selectedLabFacilities.contains(facility);
  }

  Future<void> getFacilityWiseDataForPickup() async {
    if (userData.value == null) {
      debugPrint('⚠️ User data not loaded yet');
      return;
    }

    try {
      isLoading.value = true;
      final dateString = DateFormat('yyyy/MM/dd').format(selectedDate.value);
      final reqBody = {
        'LabCode': labCode.value, // todo
        'FtypeId': 0,
        'FtypeCat': '',
        'UserID': userData.value!.empCode,
        'date': dateString,
      };

      debugPrint('📤 Sending Request: $reqBody');

      final response = await samplePickupService.fetchFacilityWiseDataForPickup(
        reqBody,
      );
      facilityPickupList.assignAll(response);

      debugPrint(
        '✅ Facility data fetched: ${facilityPickupList.length} records',
      );
    } catch (e) {
      debugPrint('❌ Error fetching facility pickup data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getSubmitToLabFacilityData() async {
    if (userData.value == null) {
      debugPrint('⚠️ User data not loaded yet');
      return;
    }

    try {
      isLoading.value = true;

      // Format date as YYYY-MM-DD
      final dateString = selectedDate.value.toString().split(' ')[0];
      debugPrint(
        '🔍 Fetching daily work for: ${userData.value?.empCode}, Date: $dateString',
      );

      final List<WorkItem> response = await samplePickupService
          .getDailyWorkList(userData.value!.empCode.toString(), dateString, 1);
      workList.value = response;
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
      await getFacilityWiseDataForPickup();
    }
  }

  void clearSignature() {
    signatureController.clear();
  }

  Future<String?> _saveSignature() async {
    try {
      if (signatureController.isEmpty) {
        Get.snackbar('Error', 'Please provide a signature');
        return null;
      }

      final signatureBytes = await signatureController.toPngBytes();
      if (signatureBytes == null) {
        Get.snackbar('Error', 'Failed to capture signature');
        return null;
      }

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/phlebo_signature.png';
      final file = File(filePath);
      await file.writeAsBytes(signatureBytes);

      return filePath;
    } catch (e) {
      debugPrint('❌ Error saving signature: $e');
      Get.snackbar('Error', 'Failed to save signature');
      return null;
    }
  }

  /*Future<String?> _uploadSignature(String filePath) async {
    try {
      isLoading.value = true;
      final uri = Uri.parse(AppUrls.insRunnerBoyDailyWork);
      final request = http.MultipartRequest('POST', uri);

      // Add form fields matching Java code
      request.fields['RunnerBoyUserid'] = (userData.value!.empCode ?? '').toString();
      request.fields['FacilityCode'] = (selectedFacility.value!.facilityCode ?? '').toString();
      request.fields['Lattitude'] = '17.333211'; ///todo
      request.fields['Longitude'] = '75.242143'; ///todo
      request.fields['Date'] = DateFormat('yyyy/MM/dd').format(selectedDate.value);

      // Add signature file
      request.files.add(await http.MultipartFile.fromPath('Photo', filePath));

      print('📡 Submitting Signature Upload Request');
      print('➡️ URL: $uri');
      print('➡️ Headers: ${request.headers}');
      print('➡️ Fields: ${request.fields}');
      print('➡️ File: $filePath');

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('📬 Signature Upload Response');
      print('⬅️ Status Code: ${response.statusCode}');
      print('⬅️ Body: $responseBody');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(responseBody);
          if (responseData['status']?.toString().toLowerCase() == 'success') {
            final output = responseData['output'] as List?;
            if (output != null && output.isNotEmpty) {
              final workId = output[0]['ID']?.toString();
              print('✅ WorkID: $workId');
              return workId;
            } else {
              Get.snackbar('Error', 'No WorkID returned in response');
              return null;
            }
          } else {
            Get.snackbar('Error', responseData['message'] ?? 'Failed to upload signature');
            return null;
          }
        } catch (e) {
          print('❌ Error parsing response: $e');
          Get.snackbar('Error', 'Invalid response format: $e');
          return null;
        }
      } else {
        Get.snackbar('Error', 'Failed to upload signature: HTTP ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error uploading signature: $e');
      Get.snackbar('Error', 'Failed to upload signature: $e');
      return null;
    } finally {
      isLoading.value = false;
      try {
        await File(filePath).delete();
        print('🗑️ Deleted temporary file: $filePath');
      } catch (e) {
        print('❌ Failed to delete temporary file: $e');
      }
    }
  }

  Future<void> _submitCounts(String workId) async {
    try {
      isLoading.value = true;
      final uri = Uri.parse(AppUrls.insRunnerBoyDailyWorkVisitedFacility);

      // Create the JSON data structure exactly like Java code
      final jsonData = {
        'input': [
          {
            'WorkID': workId,
            'RunnerBoyuserid': userData.value!.empCode,
            'FacilityCode': selectedFacility.value!.facilityCode,
            'Latitude': '17.333211', // Replace with actual location data// todo
            'Longitude': '75.242143', // Replace with actual location data.. todo
            'SampleCount': trfRController.text,
            'tubeCount': tubeCountRController.text,
            'Remark': remarkController.text,
            'SampleCollectedOfDate': DateFormat('yyyy/MM/dd').format(selectedDate.value),
          }
        ]
      };

      // Convert to JSON string
      final jsonString = jsonEncode(jsonData);

      debugPrint('📤 Sending JSON data: $jsonString');

      // Send as form data with 'jsonstring' key (matching Java implementation)
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'jsonstring': jsonString,
        },
      );

      debugPrint('📬 Counts Submission Response');
      debugPrint('⬅️ Status Code: ${response.statusCode}');
      debugPrint('⬅️ Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = jsonDecode(response.body);
          final status = responseData['status']?.toString().toLowerCase();
          final message = responseData['message']?.toString();

          if (status == 'success') {
            SnackBarService.to.showMessage(message: 'Sample Pick-up entry saved successfully', backgroundColor: AppColors.tertiary);
            */ /*Get.snackbar(
              'Success',
              'Sample collection entry saved successfully!',
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.green,
              colorText: Colors.white,
            );*/ /*

            // Clear form data
            clearSignature();
            remarkController.clear();
            trfRController.clear();
            tubeCountRController.clear();
            selectedFacility.value = null;

            // Refresh facility data
            await getFacilityWiseDataForPickup();

          } else {
            Get.snackbar('Error', message ?? 'Failed to submit data');
          }
        } catch (e) {
          debugPrint('❌ Error parsing response: $e');
          Get.snackbar('Error', 'Invalid response format: $e');
        }
      } else {
        Get.snackbar('Error', 'Failed to submit counts: HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error submitting counts: $e');
      Get.snackbar('Error', 'Failed to submit counts: $e');
    } finally {
      isLoading.value = false;
    }
  }*/
  Future<String?> _uploadSignature(String filePath) async {
    try {
      isLoading.value = true;

      final url = AppUrls.insRunnerBoyDailyWork;

      final formData = FormData.fromMap({
        'RunnerBoyUserid': (userData.value!.empCode ?? '').toString(),

        'FacilityCode': (selectedFacility.value!.facilityCode ?? '').toString(),

        'Lattitude': '17.333211', // TODO: actual latitude
        'Longitude': '75.242143', // TODO: actual longitude

        'Date': DateFormat('yyyy/MM/dd').format(selectedDate.value),

        'Photo': await MultipartFile.fromFile(
          filePath,
          filename: 'signature_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      });

      debugPrint('📡 Submitting Signature Upload Request');
      debugPrint('➡️ URL: $url');
      debugPrint('➡️ File: $filePath');

      final response = await apiClient.post(url, data: formData);

      final responseData = response.body;

      HelperMethods.printLongString(
        '📬 Signature Upload Response: $responseData',
      );

      if (response.statusCode == 200) {
        final status = responseData['status']?.toString().toLowerCase();

        if (status == 'success') {
          final output = responseData['output'] as List?;

          if (output != null && output.isNotEmpty) {
            final workId = output[0]['ID']?.toString();

            debugPrint('✅ WorkID: $workId');

            return workId;
          }

          Get.snackbar('Error', 'No WorkID returned in response');

          return null;
        }

        Get.snackbar(
          'Error',
          responseData['message']?.toString() ?? 'Failed to upload signature',
        );

        return null;
      }

      Get.snackbar(
        'Error',
        'Failed to upload signature: HTTP ${response.statusCode}',
      );

      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ Error uploading signature: $e');
      debugPrintStack(stackTrace: stackTrace);

      Get.snackbar('Error', 'Failed to upload signature: $e');

      return null;
    } finally {
      isLoading.value = false;

      try {
        await File(filePath).delete();
        debugPrint('🗑️ Deleted temporary file: $filePath');
      } catch (e) {
        debugPrint('❌ Failed to delete temporary file: $e');
      }
    }
  }

  Future<void> _submitCounts(String workId) async {
    try {
      isLoading.value = true;

      final url = AppUrls.insRunnerBoyDailyWorkVisitedFacility;

      final jsonData = {
        'input': [
          {
            'WorkID': workId,
            'RunnerBoyuserid': userData.value!.empCode,
            'FacilityCode': selectedFacility.value!.facilityCode,
            'Latitude': '17.333211', // TODO: actual latitude
            'Longitude': '75.242143', // TODO: actual longitude
            'SampleCount': trfRController.text,
            'tubeCount': tubeCountRController.text,
            'Remark': remarkController.text,
            'SampleCollectedOfDate': DateFormat(
              'yyyy/MM/dd',
            ).format(selectedDate.value),
          },
        ],
      };

      final jsonString = jsonEncode(jsonData);

      debugPrint('📤 Sending Counts Submission');
      debugPrint('➡️ URL: $url');
      debugPrint('➡️ jsonstring: $jsonString');

      final response = await apiClient.post(
        url,
        data: {'jsonstring': jsonString},
      );

      final responseData = response.body;

      debugPrint('📬 Counts Submission Response');
      debugPrint('⬅️ Status Code: ${response.statusCode}');
      HelperMethods.printLongString('⬅️ Body: $responseData');

      if (response.statusCode != 200) {
        Get.snackbar(
          'Error',
          'Failed to submit counts: HTTP ${response.statusCode}',
        );
        return;
      }

      final status = responseData['status']?.toString().toLowerCase();

      final message = responseData['message']?.toString();

      if (status == 'success') {
        SnackBarService.to.showMessage(
          message: 'Sample Pick-up entry saved successfully',
          backgroundColor: AppColors.tertiary,
        );

        // Clear form data
        clearSignature();
        remarkController.clear();
        trfRController.clear();
        tubeCountRController.clear();

        selectedFacility.value = null;

        // Refresh facility data
        await getFacilityWiseDataForPickup();
      } else {
        Get.snackbar('Error', message ?? 'Failed to submit data');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error submitting counts: $e');
      debugPrintStack(stackTrace: stackTrace);

      Get.snackbar('Error', 'Failed to submit counts: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitData() async {
    if (selectedFacility.value == null) {
      Get.snackbar('Error', 'Please select a facility');
      return;
    }

    final filePath = await _saveSignature();
    if (filePath == null) return;

    final workId = await _uploadSignature(filePath);
    if (workId == null) return;

    await _submitCounts(workId);
  }

  Future<void> submitToLab() async {
    if (selectedLabFacilities.isEmpty) {
      Get.snackbar('Error', 'Please select at least one facility');
      return;
    }

    /*  // Show confirmation dialog first (matching Android behavior)
    final confirmed = await _showSubmitConfirmationDialog();
    if (!confirmed) return;*/

    try {
      isLoading.value = true;

      /*// Filter only facilities that haven't been submitted yet (IsSubmittedAccepted == "0")
      final validFacilities = selectedLabFacilities
          .where((facility) => facility.isSubmittedAccepted == "0")
          .toList();

      if (validFacilities.isEmpty) {
        Get.snackbar('Error', 'You have already submitted the samples to lab');
        return;
      }*/

      // Create submission data matching Android JsonObject structure
      final submissionData = selectedLabFacilities
          .map(
            (facility) => {
              'SubmittedBy': userData.value!.empCode.toString(),
              'AcceptedBy': '0',
              'LabCode': 160, // todo 😈😈😈
              'WORKID': facility.workId,
              'Tubecount_L': '', // Empty as per Android code
              'TRFcount_L': '', // Empty as per Android code
              'FacilityCode': facility.facilityCode,
            },
          )
          .toList();

      debugPrint('📤 Submitting to lab: ${submissionData.length} facilities');

      final response = await samplePickupService.submitSamplesToLab(
        submissionData,
      );

      final status = response['status']?.toString().toLowerCase();
      final message = response['message']?.toString() ?? '';

      if (status == 'success') {
        SnackBarService.to.showMessage(
          message: 'Samples submitted to lab successfully!',
        );

        /*Get.snackbar(
          'Success',
          'Samples submitted to lab successfully!',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );*/

        // Clear selections and refresh data
        selectedLabFacilities.clear();
        await getSubmitToLabFacilityData();
      } else {
        Get.snackbar(
          'Error',
          message.isNotEmpty ? message : 'Failed to submit samples to lab',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      debugPrint('❌ Error submitting to lab: $e');
      Get.snackbar(
        'Error',
        'Failed to submit to lab. Please try again.',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // 4. Add confirmation dialog method (matching Android AlertDialog)
  Future<bool> _showSubmitConfirmationDialog() async {
    return await Get.dialog<bool>(
          AlertDialog(
            title: const Text('Alert'),
            content: const Text(
              'It is mandatory to submit sample in front of lab person',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(result: false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Get.back(result: true),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                child: const Text('Proceed'),
              ),
            ],
          ),
          barrierDismissible: false,
        ) ??
        false;
  }
}
