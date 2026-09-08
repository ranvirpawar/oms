
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide SnackPosition;
import 'package:intl/intl.dart';
import 'package:lifenity_connect/features/lab_technician/sample_accept/model/sample_temparature_model.dart';
import 'package:lifenity_connect/features/lab_technician/sample_accept/service/sample_accept_service.dart';

import '../../../../utils/ui_designs/liquid_snackbar.dart';
import '../../../phlebotomist/sample_pickup/model/work_item_model.dart';
import '../model/resource_model.dart';

class AcceptInLabController extends GetxController {
  final ResourcesData resource;
  final DateTime selectedDate;
  final String labCode;
  final String labTechnicianId;
  final isLoading = true.obs;
  final workList = <WorkItem>[].obs;
  final temperatureData = <SampleTemperatureData>[].obs;
  final selectedLabFacilities = <WorkItem>[].obs;
  final selectedTemperatureData = <SampleTemperatureData>[].obs;
  final selectedTemperature = ''.obs;
  final remarkController = TextEditingController();

  // Change this to a regular Map instead of observable
  final Map<WorkItem, Map<String, TextEditingController>> textControllers = {};

  final SampleAcceptService sampleAcceptService = Get.put(SampleAcceptService());

  AcceptInLabController(this.resource, this.selectedDate, this.labCode, this.labTechnicianId);

  @override
  void onInit() {
    super.onInit();
    fetchFacilityData();
    fetchTemperatureData();
  }

  @override
  void onClose() {
    remarkController.dispose();
    textControllers.forEach((_, controllers) {
      controllers['trfL']?.dispose();
      controllers['tubeCountL']?.dispose();
    });
    super.onClose();
  }

  Future<void> fetchFacilityData() async {
    isLoading.value = true;
    try {
      final dateFormat = DateFormat('yyyy-MM-dd');
      final formattedDate = dateFormat.format(selectedDate);
      final facilities = await sampleAcceptService.getListOfFacilitiesForSubmission(
        resource.userId.toString(),
        formattedDate,
      );
      workList.assignAll(facilities);
    } catch (e) {
      LiquidSnack.error('Failed to load facility data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchTemperatureData() async {
    isLoading.value = true;
    try {
      final temperatureDataResponse = await sampleAcceptService.getTemperatureDropdown();
      temperatureData.assignAll(temperatureDataResponse);
    } catch (e) {
      LiquidSnack.error('Failed to load temp data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void selectTemperature(String? value) {
    if (value != null) {
      selectedTemperature.value = value;
      final selectedTemp = temperatureData.firstWhere(
            (item) => item.sampleTempName == value,
        orElse: () => temperatureData.isNotEmpty
            ? temperatureData[0]
            : SampleTemperatureData(sampleTempName: '', sampleTempId: 0),
      );
      selectedTemperatureData.assignAll([selectedTemp]);
    }
  }

  void toggleLabFacilitySelection(WorkItem facility) {
    if (selectedLabFacilities.contains(facility)) {
      selectedLabFacilities.remove(facility);
      // Dispose controllers when removing
      final controllers = textControllers.remove(facility);
      controllers?['trfL']?.dispose();
      controllers?['tubeCountL']?.dispose();
    } else {
      selectedLabFacilities.add(facility);
      // Create controllers immediately when selecting
      _createTextControllers(facility);
    }
  }

  void _createTextControllers(WorkItem facility) {
    textControllers[facility] = {
      'trfL': TextEditingController(text: facility.trfCountL?.toString() ?? ''),
      'tubeCountL': TextEditingController(text: facility.tubeCountL?.toString() ?? ''),
    };
  }

  Map<String, TextEditingController> getTextControllers(WorkItem facility) {
    // Don't create controllers here during build - just return existing ones
    return textControllers[facility] ?? {
      'trfL': TextEditingController(),
      'tubeCountL': TextEditingController(),
    };
  }

  Future<void> submitToLab() async {
    // Validate selections
    if (selectedLabFacilities.isEmpty) {
LiquidSnack.warning('Please select at least one facility');
      return;
    }
    if (selectedTemperature.value.isEmpty) {
LiquidSnack.warning('Please select a temperature');
      return;
    }

    // Check if remark is mandatory
    bool isRemarkMandatory = false;
    for (var facility in selectedLabFacilities) {
      final controllers = textControllers[facility]!;
      final trfL = controllers['trfL']!.text.isNotEmpty
          ? int.parse(controllers['trfL']!.text)
          : facility.sampleCount;
      final tubeCountL = controllers['tubeCountL']!.text.isNotEmpty
          ? int.parse(controllers['tubeCountL']!.text)
          : facility.tubeCount;

      if (trfL != facility.sampleCount || tubeCountL != facility.tubeCount) {
        isRemarkMandatory = true;
        break;
      }
    }

    if (isRemarkMandatory && remarkController.text.isEmpty) {
LiquidSnack.warning('Please enter a remark');
      return;
    }

    // Validate TRF and Tube counts
    for (var facility in selectedLabFacilities) {
      final controllers = textControllers[facility];
      if (controllers == null ||
          controllers['trfL']!.text.isEmpty ||
          controllers['tubeCountL']!.text.isEmpty) {
LiquidSnack.warning('Please fill TRF and Tubes for all selected facilities');
        return;
      }
    }

    try {
      isLoading.value = true;

      // Prepare submission data
      final submissionData = selectedLabFacilities.map((facility) {
        final controllers = textControllers[facility]!;
        return {
          'SubmittedBy': '0',   /* 'SubmittedBy': resource.userId.toString(),*/
          'AcceptedBy': labTechnicianId,
          'LabCode': labCode,
          'WORKID': facility.workId.toString(),
          'Tubecount_L': controllers['tubeCountL']!.text.isNotEmpty
              ? controllers['tubeCountL']!.text
              : facility.tubeCount.toString() ,
          'TRFcount_L': controllers['trfL']!.text.isNotEmpty
              ? controllers['trfL']!.text
              : facility.sampleCount.toString(),
          'FacilityCode': facility.facilityCode.toString(),
        };
      }).toList();

      // Find selected temperature ID
      final selectedTemp = temperatureData.firstWhere(
            (item) => item.sampleTempName == selectedTemperature.value,
        orElse: () => SampleTemperatureData(sampleTempName: '', sampleTempId: 0),
      );

      // Call API via service
      final service = SampleAcceptService();
      final result = await service.submitSamplesToLab(
        submissionData: submissionData,
        remark: remarkController.text,
        temperatureId: selectedTemp.sampleTempId,
      );

      // Handle response
      final status = result['status']?.toLowerCase();
      final message = result['message'] ?? '';

      if (status == 'success') {
LiquidSnack.success('Samples accepted in lab successfully!');

        // Reset state
        selectedLabFacilities.clear();
        // Dispose controllers before clearing
        textControllers.forEach((_, controllers) {
          controllers['trfL']?.dispose();
          controllers['tubeCountL']?.dispose();
        });
        textControllers.clear();
        selectedTemperature.value = '';
        remarkController.clear();
        await fetchFacilityData();
      } else {
LiquidSnack.error(message.isNotEmpty ? message : 'Failed to accept samples in lab');
      }
    } catch (e) {
LiquidSnack.error('Failed to accept samples: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
/*class AcceptInLabController extends GetxController {
  final ResourcesData resource;
  final DateTime selectedDate;
  final String labCode;
  final String labTechnicianId;
  final isLoading = true.obs;
  final workList = <WorkItem>[].obs;
  final temperatureData = <SampleTemperatureData>[].obs;
  final selectedLabFacilities = <WorkItem>[].obs;
  final selectedTemperatureData = <SampleTemperatureData>[].obs;
  final selectedTemperature = ''.obs;
  final remarkController = TextEditingController();
  final Map<WorkItem, Map<String, TextEditingController>> textControllers = {};
  final SampleAcceptService sampleAcceptService = Get.put(SampleAcceptService());
  AcceptInLabController(this.resource, this.selectedDate, this.labCode, this.labTechnicianId);

  @override
  void onInit() {
    super.onInit();
    fetchFacilityData();
    fetchTemperatureData();
  }

  @override
  void onClose() {
    remarkController.dispose();
    textControllers.forEach((_, controllers) {
      controllers['trfL']?.dispose();
      controllers['tubeCountL']?.dispose();
    });
    super.onClose();
  }

  Future<void> fetchFacilityData() async {
    isLoading.value = true;
    try {
      final dateFormat = DateFormat('yyyy-MM-dd');
      final formattedDate = dateFormat.format(selectedDate);
      final facilities = await sampleAcceptService.getListOfFacilitiesForSubmission(
        resource.userId.toString(),
        formattedDate,
      );
      workList.assignAll(facilities);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load facility data: $e');
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> fetchTemperatureData() async {
    isLoading.value = true;
    try {

      final temperatureDataResponse = await sampleAcceptService.getTemperatureDropdown(

      );
      temperatureData.assignAll(temperatureDataResponse);
    } catch (e) {
      Get.snackbar('Error', 'Failed to load temp data: $e');
    } finally {
      isLoading.value = false;
    }
  }


  void selectTemperature(String? value) {
    if (value != null) {
      selectedTemperature.value = value;
      // Optionally update selectedTemperatureData if needed
      final selectedTemp = temperatureData.firstWhere(
            (item) => item.sampleTempName == value,
        orElse: () => temperatureData.isNotEmpty
            ? temperatureData[0]
            : SampleTemperatureData(sampleTempName: '', sampleTempId: 0),
      );
      selectedTemperatureData.assignAll([selectedTemp]);
    }
  }

  void toggleLabFacilitySelection(WorkItem facility) {
    if (selectedLabFacilities.contains(facility)) {
      selectedLabFacilities.remove(facility);
      textControllers.remove(facility);
    } else {
      selectedLabFacilities.add(facility);
      textControllers[facility] = {
        'trfL': TextEditingController(text: facility.trfCountL?.toString() ?? ''),
        'tubeCountL': TextEditingController(text: facility.tubeCountL?.toString() ?? ''),
      };
    }
  }

  Map<String, TextEditingController> getTextControllers(WorkItem facility) {
    if (!textControllers.containsKey(facility)) {
      textControllers[facility] = {
        'trfL': TextEditingController(text: facility.trfCountL?.toString() ?? ''),
        'tubeCountL': TextEditingController(text: facility.tubeCountL?.toString() ?? ''),
      };
    }
    return textControllers[facility]!;
  }

  Future<void> submitToLab() async {
    // 🔹 Validate selections
    if (selectedLabFacilities.isEmpty) {
      Get.snackbar('Error', 'Please select at least one facility',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }
    if (selectedTemperature.value.isEmpty) {
      Get.snackbar('Error', 'Please select a temperature',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    // 🔹 Check if remark is mandatory
    bool isRemarkMandatory = false;
    for (var facility in selectedLabFacilities) {
      final controllers = textControllers[facility]!;
      final trfL = controllers['trfL']!.text.isNotEmpty
          ? int.parse(controllers['trfL']!.text)
          : facility.sampleCount;
      final tubeCountL = controllers['tubeCountL']!.text.isNotEmpty
          ? int.parse(controllers['tubeCountL']!.text)
          : facility.tubeCount;

      if (trfL != facility.sampleCount || tubeCountL != facility.tubeCount) {
        isRemarkMandatory = true;
        break;
      }
    }

    if (isRemarkMandatory && remarkController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter a remark',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white);
      return;
    }

    // 🔹 Validate TRF and Tube counts
    for (var facility in selectedLabFacilities) {
      final controllers = textControllers[facility];
      if (controllers == null ||
          controllers['trfL']!.text.isEmpty ||
          controllers['tubeCountL']!.text.isEmpty) {
        Get.snackbar('Error', 'Please fill TRF and Tubes for all selected facilities',
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.red,
            colorText: Colors.white);
        return;
      }
    }

    try {
      isLoading.value = true;

      // 🔹 Prepare submission data
      final submissionData = selectedLabFacilities.map((facility) {
        final controllers = textControllers[facility]!;
        return {
          'SubmittedBy': resource.userId.toString(),
          'AcceptedBy': labTechnicianId,
          'LabCode': labCode,
          'WORKID': facility.workId.toString(),
          'Tubecount_L': controllers['tubeCountL']!.text.isNotEmpty
              ? controllers['tubeCountL']!.text
              : facility.tubeCount?.toString() ?? '0',
          'TRFcount_L': controllers['trfL']!.text.isNotEmpty
              ? controllers['trfL']!.text
              : facility.sampleCount?.toString() ?? '0',
          'FacilityCode': facility.facilityCode.toString(),
        };
      }).toList();

      // 🔹 Find selected temperature ID
      final selectedTemp = temperatureData.firstWhere(
            (item) => item.sampleTempName == selectedTemperature.value,
        orElse: () => SampleTemperatureData(sampleTempName: '', sampleTempId: 0),
      );

      // 🔹 Call API via service
      final service = SampleAcceptService();
      final result = await service.submitSamplesToLab(
        submissionData: submissionData,
        remark: remarkController.text,
        temperatureId: selectedTemp.sampleTempId,
      );

      // 🔹 Handle response
      final status = result['status']?.toLowerCase();
      final message = result['message'] ?? '';

      if (status == 'success') {
        Get.snackbar(
          'Success',
          'Samples accepted in lab successfully!',
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.primary,
          colorText: Colors.white,
        );

        // Reset state
        selectedLabFacilities.clear();
        textControllers.clear();
        selectedTemperature.value = '';
        remarkController.clear();
        await fetchFacilityData();
      } else {
        Get.snackbar(
          'Error',
          message.isNotEmpty ? message : 'Failed to accept samples in lab',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to accept samples: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

}*/

/*class AcceptInLabController extends GetxController {
  final ResourcesData resource;
  final DateTime selectedDate;
  final isLoading = true.obs;
  final workItem = Rxn<WorkItem>();
  final selectedTemperature = ''.obs;
  final remarkController = TextEditingController();

  final SampleAcceptService sampleAcceptService = Get.put(SampleAcceptService());

  AcceptInLabController(this.resource, this.selectedDate);

  @override
  void onInit() {
    super.onInit();
    fetchFacilityData();
  }

  Future<void> fetchFacilityData() async {
    isLoading.value = true;
    try {
      final dateFormat = DateFormat('yyyy-MM-dd');
      final formattedDate = dateFormat.format(selectedDate);
      final facilities = await sampleAcceptService.getListOfFacilitiesForSubmission(
        resource.userId.toString(),
        formattedDate,
      );
      if (facilities.isNotEmpty) {
        workItem.value = facilities.first;
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load facility data: $e');
    } finally {
      isLoading.value = false;
    }
  }


  void selectTemperature(String? value) {
    if (value != null) {
      selectedTemperature.value = value;
    }
  }

  void submitToLab() {
    // Dummy submission method
    if (selectedTemperature.value.isEmpty) {
      Get.snackbar('Error', 'Please select a temperature');
      return;
    }
    if (remarkController.text.isEmpty) {
      Get.snackbar('Error', 'Please enter a remark');
      return;
    }

    // Simulate submission
    Get.snackbar(
      'Success',
      'Samples accepted in lab with temperature: ${selectedTemperature.value}',
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
    );

    // Clear fields after submission
    selectedTemperature.value = '';
    remarkController.clear();
  }
}*/
