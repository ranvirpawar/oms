import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_registration/service/patient_registration_service.dart';
import 'package:lifenity_connect/features/team_lead/invoice_tracking/service/invoice_tracking_service.dart';
import 'package:lifenity_connect/services/snackbar_service.dart';

import '../../../../services/user_service.dart';
import '../../../../theme/app_colors.dart';
import '../../../auth/model/login_response_model.dart';
import '../model/billing_month_model.dart';
import '../model/billing_year_model.dart';
import '../model/invoice_model.dart';
import 'package:file_picker/file_picker.dart';

import '../model/new_facility_model.dart';
import '../model/new_facility_type_model.dart';
import '../view/widget/invoice_stage_bottomsheet.dart';

class InvoiceTrackingController extends GetxController {
  final UserService userService = Get.put(UserService());
  final PatientRegistrationService _registrationService =
      Get.put(PatientRegistrationService());
  final InvoiceTrackingService _invoiceTrackingService =
      Get.put(InvoiceTrackingService());

  RxBool isLoading = false.obs;
  RxBool isSearching = false.obs;
  RxBool isSubmitting = false.obs;
  RxBool isFacilityLoading = false.obs;
  RxBool isUploadingFiles = false.obs; // NEW: For file upload progress
  Rx<UserModel?> user = Rx<UserModel?>(null);
  RxString userId = ''.obs;

  // Dropdowns
  final RxList<String> wards = <String>[].obs;
  final RxString selectedWard = ''.obs;

  final RxList<NewFacilityType> facilityTypes = <NewFacilityType>[].obs;
  final Rx<NewFacilityType?> selectedFacilityType = Rx<NewFacilityType?>(null);

  final RxList<NewFacilityModel> facilityNames = <NewFacilityModel>[].obs;
  final Rx<NewFacilityModel?> selectedFacilityName =
      Rx<NewFacilityModel?>(null);

  // Year and Month data
  final RxList<BillingYear> years = <BillingYear>[].obs;
  final RxList<BillingMonth> months = <BillingMonth>[].obs;
  final Rx<BillingYear?> selectedYear = Rx<BillingYear?>(null);
  final Rx<BillingMonth?> selectedMonth = Rx<BillingMonth?>(null);

  // Invoice data
  final RxList<InvoiceStatus> invoiceList = <InvoiceStatus>[].obs;
  final Rx<InvoiceStatus?> selectedInvoice = Rx<InvoiceStatus?>(null);

  // Stage data - ALL stages from API
  final RxList<InvoiceStage> stages = <InvoiceStage>[].obs;

  Rx<InvoiceStage?> get nextStage {
    if (stages.isEmpty) return Rx<InvoiceStage?>(null);

    final sorted = stages.toList()
      ..sort((a, b) => a.processId.compareTo(b.processId));

    if (isTeamLeadLogin.value) {
      return Rx<InvoiceStage?>(sorted.first);
    }

    final hasStage3 = sorted.any((s) => s.processId == 3);
    if (!hasStage3) return Rx<InvoiceStage?>(null);

    final stage3 = sorted.firstWhere((s) => s.processId == 3);
    return Rx<InvoiceStage?>(stage3);
  }

  final Rx<InvoiceStage?> selectedStage = Rx<InvoiceStage?>(null);

  // UPDATED: File upload - Support both PDF and Images
  Rx<File?> selectedFile = Rx<File?>(null); // For PDF
  RxString selectedFileName = ''.obs;

  // NEW: Multiple image files support
  final RxList<File> selectedImageFiles = <File>[].obs;

  // BR Number field (for stage 24)
  RxString brNumber = ''.obs;

  RxBool isTeamLeadLogin = false.obs;

  // Stages that require file upload
  final List<int> stagesRequiringFileUpload = [11];

  // Stage that can be updated only by phlebotomist
  final List<int> stagesRequiringPhlebotomistUpdate = [3];

  // Stages that require BR number
  final List<int> stagesRequiringBRNumber = [24];

  @override
  void onInit() {
    super.onInit();
    loadUser();
  }

  void loadUser() async {
    try {
      final userData = await userService.getUser();
      if (userData != null) {
        user.value = userData;
        userId.value = user.value?.empCode.toString() ?? '';
        isTeamLeadLogin.value = user.value?.designation == 'Team Lead';
        debugPrint('User Designation: ${user.value?.designation}');
        debugPrint('✅ User data loaded: ${user.value?.name}');
        fetchDropdownData();
      } else {
        debugPrint('❌ Failed to load user data');
      }
    } catch (e) {
      debugPrint('❌ Error loading user: $e');
    }
  }

  void fetchDropdownData() {
    getWardsList();
    getFacilityCenterTypes();
    getYearDropdown();
  }

  void getWardsList() async {
    try {
      isLoading.value = true;
      final facilities =
          await _registrationService.getFacilityList(userId.value);
      wards.assignAll(
          facilities.map((f) => f.ward).whereType<String>().toSet().toList());

      if (wards.isNotEmpty) selectedWard.value = wards.first;
    } catch (e) {
      SnackBarService.to.showMessage(message: 'Failed to load wards');
    } finally {
      isLoading.value = false;
    }
  }

  void getFacilityCenterTypes() async {
    try {
      final types =
          await _invoiceTrackingService.getFacilityTypeList(userId.value);
      facilityTypes.assignAll(types);
      if (types.isNotEmpty) selectedFacilityType.value = types.first;
    } catch (e) {
      SnackBarService.to.showMessage(message: 'Failed to load facility types');
    }
  }

  void fetchFacilityNames() async {
    if (selectedWard.value.isEmpty || selectedFacilityType.value == null) {
      facilityNames.clear();
      selectedFacilityName.value = null;
      return;
    }

    try {
      isFacilityLoading.value = true;
      final list = await _invoiceTrackingService.getFacilityList(
        userId: userId.value,
        ward: selectedWard.value,
        facilityTypeId: selectedFacilityType.value!.fTypeId,
      );
      if (list.isEmpty) {
        SnackBarService.to
            .showMessage(message: 'No facilities found, check filters');
      }

      facilityNames.assignAll(list);
      selectedFacilityName.value = list.isNotEmpty ? list.first : null;
    } catch (e) {
      SnackBarService.to.showMessage(message: 'Failed to load facility names');
      facilityNames.clear();
      selectedFacilityName.value = null;
    } finally {
      isFacilityLoading.value = false;
    }
  }

  void onWardChanged(String? value) {
    if (value == null) return;
    selectedWard.value = value;
    fetchFacilityNames();
  }

  void onFacilityTypeChanged(String? name) {
    if (name == null) return;
    final type = facilityTypes.firstWhere((t) => t.fTypeName == name);
    selectedFacilityType.value = type;
    fetchFacilityNames();
  }

  void onFacilityNameChanged(String? name) {
    if (name == null || name.isEmpty) {
      selectedFacilityName.value = null;
      return;
    }
    final selected = facilityNames.firstWhere((f) => f.facilityName == name);
    selectedFacilityName.value = selected;
  }

  void getYearDropdown() async {
    try {
      final yearList = await _invoiceTrackingService.fetchYearDropdown();
      years.assignAll(yearList);

      if (years.isNotEmpty) {
        selectedYear.value = years.first;
        getBillingMonth();
      }

      debugPrint('✅ Loaded ${years.length} years');
    } catch (e) {
      SnackBarService.to.showMessage(
        message: 'Failed to load years',
      );
    }
  }

  void getBillingMonth() async {
    try {
      final monthList = await _invoiceTrackingService
          .fetchBillingMonth(selectedYear.value!.year);
      months.assignAll(monthList);

      if (months.isNotEmpty) {
        selectedMonth.value = months.last;
      }

      debugPrint('✅ Loaded ${months.length} months');
    } catch (e) {
      SnackBarService.to.showMessage(message: 'Failed to load billing months');
    }
  }

  void getInvoiceStages() async {
    try {
      final invoiceId = selectedInvoice.value?.invoiceId;

      final stageList =
          await _invoiceTrackingService.getInvoiceStages(invoiceId.toString());

      stageList.sort((a, b) => a.processId.compareTo(b.processId));
      stages.assignAll(stageList);

      debugPrint('✅ Loaded ${stages.length} stages');
      debugPrint(
          '✅ Next available stage: ${nextStage.value?.processDescription} (ID: ${nextStage.value?.processId})');
    } catch (e) {
      SnackBarService.to.showMessage(
        message: 'Failed to load invoice stages',
      );
    }
  }

  void onYearChanged(String value) {
    final year = years.firstWhere(
      (y) => y.year == int.parse(value),
    );

    selectedYear.value = year;
    selectedMonth.value = null;
    months.clear();

    getBillingMonth();
  }

  void toggleInvoiceSelection(InvoiceStatus invoice) {
    if (selectedInvoice.value?.invoiceId == invoice.invoiceId) {
      selectedInvoice.value = null;
      selectedStage.value = null;
      clearAllFiles();
      brNumber.value = '';
      debugPrint('🔄 Invoice unselected');
    } else {
      selectedInvoice.value = invoice;
      selectedStage.value = null;
      clearAllFiles();
      brNumber.value = '';
      getInvoiceStages();
      debugPrint('✅ Invoice selected: ${invoice.invoiceNumber}');
    }
  }

  void searchInvoices() async {
    HapticFeedback.lightImpact();
    if (selectedYear.value == null) {
      SnackBarService.to.showMessage(
        message: 'Please select a year',
      );
      return;
    }

    if (selectedMonth.value == null) {
      SnackBarService.to.showMessage(
        message: 'Please select a month',
      );
      return;
    }

    if (selectedFacilityName.value == null) {
      SnackBarService.to.showMessage(
        message: 'Please select a facility',
      );
      return;
    }

    try {
      isSearching.value = true;
      invoiceList.clear();
      selectedInvoice.value = null;
      selectedStage.value = null;
      clearAllFiles();
      brNumber.value = '';

      final invoices =
          await _invoiceTrackingService.getFacilityWiseInvoiceStatus(
        yearId: selectedYear.value!.year,
        monthId: selectedMonth.value!.monthId,
        facilityCode: selectedFacilityName.value!.facilityCode,
      );

      invoiceList.assignAll(invoices);

      if (invoices.isNotEmpty) {
        SnackBarService.to
            .showMessage(message: 'Found ${invoices.length} invoice(s)');
      } else {
        SnackBarService.to.showMessage(message: 'No Invoices Found');
      }
    } catch (e) {
      SnackBarService.to
          .quickNotify(message: 'Failed to fetch invoices please try again');
    } finally {
      isSearching.value = false;
    }
  }

  // NEW: Show image source selection bottom sheet
  void showImageSourceSelection() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Image Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading:
                  const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Gallery'),
              subtitle: const Text('Select multiple images'),
              onTap: () {
                Get.back();
                pickImagesFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Camera'),
              subtitle: const Text('Take a photo'),
              onTap: () {
                Get.back();
                pickImageFromCamera();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      isDismissible: true,
    );
  }

  // NEW: Pick multiple images from gallery
  Future<void> pickImagesFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        for (var image in images) {
          final File file = File(image.path);

          // Check file size (max 10MB per image)
          final int fileSizeInBytes = await file.length();
          final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

          if (fileSizeInMB > 10) {
            SnackBarService.to.showMessage(
              message: '${image.name} exceeds 10MB limit. Skipped.',
            );
            continue;
          }

          selectedImageFiles.add(file);
        }

        if (selectedImageFiles.isNotEmpty) {
          SnackBarService.to.showMessage(
            message: '${selectedImageFiles.length} image(s) selected',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error picking images: $e');
      SnackBarService.to.showMessage(message: 'Failed to pick images');
    }
  }

  // NEW: Pick image from camera
  Future<void> pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        final File file = File(image.path);

        // Check file size (max 10MB)
        final int fileSizeInBytes = await file.length();
        final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

        if (fileSizeInMB > 10) {
          SnackBarService.to.showMessage(
            message: 'Image exceeds 10MB limit',
          );
          return;
        }

        selectedImageFiles.add(file);
        SnackBarService.to.showMessage(message: 'Image captured successfully');
      }
    } catch (e) {
      debugPrint('❌ Error capturing image: $e');
      SnackBarService.to.showMessage(message: 'Failed to capture image');
    }
  }

  // NEW: Remove image file
  void removeImageFile(int index) {
    HapticFeedback.lightImpact();
    selectedImageFiles.removeAt(index);
    SnackBarService.to.showMessage(message: 'Image removed');
  }

  // EXISTING: Pick PDF file
  Future<void> pickFile() async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        final File file = File(result.files.single.path!);

        final int fileSizeInBytes = await file.length();
        final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

        if (fileSizeInMB > 50) {
          SnackBarService.to.quickNotify(
              message:
                  'File size exceeds 50MB limit. Please select a smaller file.');
          return;
        }

        selectedFile.value = file;
        selectedFileName.value = result.files.single.name;
      }
    } catch (e) {
      SnackBarService.to.showMessage(message: 'Failed to pick file');
    }
  }

  // UPDATED: Clear PDF file
  void clearFile() {
    selectedFile.value = null;
    selectedFileName.value = '';
  }

  // NEW: Clear all files
  void clearAllFiles() {
    selectedFile.value = null;
    selectedFileName.value = '';
    selectedImageFiles.clear();
  }

  bool shouldShowFileUpload() {
    return selectedStage.value != null &&
        stagesRequiringFileUpload.contains(selectedStage.value!.processId);
  }

  bool shouldShowBRNumber() {
    return selectedStage.value != null &&
        stagesRequiringBRNumber.contains(selectedStage.value!.processId) &&
        isTeamLeadLogin.value;
  }

  void showStageSelectionBottomSheet() {
    if (stages.isEmpty) return;

    Get.bottomSheet(
      StageSelectionBottomSheet(controller: this),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void selectStageFromBottomSheet(InvoiceStage stage) {
    final sortedStages = stages.toList()
      ..sort((a, b) => a.processId.compareTo(b.processId));
    final nextPendingId = sortedStages.first.processId;

    if (isTeamLeadLogin.value) {
      if (stage.processId != nextPendingId) {
        SnackBarService.to.showMessage(
          message:
              'Please complete stages in order. Next: ${sortedStages.first.processDescription}',
        );
        return;
      }

      selectedStage.value = stage;
      clearAllFiles();
      brNumber.value = '';
      Get.back();
      debugPrint('Team Lead selected: ${stage.processDescription}');
      return;
    }

    if (stage.processId != 3) {
      SnackBarService.to.showMessage(
        message: 'You are only allowed to update "Sample Collection" stage.',
      );
      return;
    }

    if (nextPendingId != 3) {
      SnackBarService.to.showMessage(
        message: 'Sample Collection stage is no longer pending.',
      );
      return;
    }

    selectedStage.value = stage;
    clearAllFiles();
    brNumber.value = '';
    Get.back();
    debugPrint('User updated Sample Collection');
  }

  // UPDATED: Submit invoice status with multiple files
  void submitInvoiceStatus() async {
    HapticFeedback.lightImpact();

    if (selectedInvoice.value == null) {
      SnackBarService.to.showMessage(message: 'Please select an invoice');
      return;
    }

    if (selectedStage.value == null) {
      SnackBarService.to.showMessage(message: 'Please select stage');
      return;
    }

    // FIXED: Only check for files if the stage requires file upload
    if (shouldShowFileUpload()) {
      if (selectedFile.value == null && selectedImageFiles.isEmpty) {
        SnackBarService.to.showMessage(
          message: 'Please upload invoice document (PDF or images)',
        );
        return;
      }
    }

    if (shouldShowBRNumber() && brNumber.value.trim().isEmpty) {
      SnackBarService.to.showMessage(message: 'Please enter BR number');
      return;
    }

    try {
      isSubmitting.value = true;
      isUploadingFiles.value = true;

      // CASE 1: Stage doesn't require file upload - direct API call
      if (!shouldShowFileUpload()) {
        final success =
            await _invoiceTrackingService.insertFacilityWiseInvoiceStatus(
          invoiceId: selectedInvoice.value!.invoiceId,
          processId: selectedStage.value!.processId,
          userId: int.parse(userId.value),
          moPathFile: null,
          // No file
          brNo: brNumber.value,
        );

        if (success) {
          SnackBarService.to.showMessage(
            message: 'Invoice Status Updated Successfully',
          );
          _resetForm();
          searchInvoices();
        }
        return;
      }

      // CASE 2: PDF is selected, upload it
      if (selectedFile.value != null) {
        final success =
            await _invoiceTrackingService.insertFacilityWiseInvoiceStatus(
          invoiceId: selectedInvoice.value!.invoiceId,
          processId: selectedStage.value!.processId,
          userId: int.parse(userId.value),
          moPathFile: selectedFile.value,
          brNo: brNumber.value,
        );

        if (success) {
          SnackBarService.to.showMessage(
            message: 'Invoice Status Updated Successfully',
          );
          _resetForm();
          searchInvoices();
        }
      }
      // CASE 3: Images are selected, upload them one by one
      else if (selectedImageFiles.isNotEmpty) {
        int successCount = 0;
        int failedCount = 0;
        final List<String> failedFiles = [];

        for (int i = 0; i < selectedImageFiles.length; i++) {
          final file = selectedImageFiles[i];
          final fileName = file.path.split('/').last;

          debugPrint(
              '📤 Uploading file ${i + 1}/${selectedImageFiles.length}: $fileName');

          try {
            final success =
                await _invoiceTrackingService.insertFacilityWiseInvoiceStatus(
              invoiceId: selectedInvoice.value!.invoiceId,
              processId: selectedStage.value!.processId,
              userId: int.parse(userId.value),
              moPathFile: file,
              brNo: brNumber.value,
            );

            if (success) {
              successCount++;
              debugPrint('✅ Successfully uploaded: $fileName');
            } else {
              failedCount++;
              failedFiles.add(fileName);
              debugPrint('❌ Failed to upload: $fileName');
            }
          } catch (e) {
            failedCount++;
            failedFiles.add(fileName);
            debugPrint('❌ Error uploading $fileName: $e');
          }
        }

        // Show result message
        if (successCount == selectedImageFiles.length) {
          SnackBarService.to.showMessage(
            message: 'All $successCount file(s) uploaded successfully',
          );
        } else if (successCount > 0) {
          SnackBarService.to.showMessage(
            message:
                '$successCount/${selectedImageFiles.length} files uploaded. $failedCount failed.',
          );
        } else {
          SnackBarService.to.showMessage(
            message: 'Failed to upload files',
          );
        }

        if (successCount > 0) {
          _resetForm();
          searchInvoices();
        }
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      debugPrint('❌  $msg');
      SnackBarService.to.showMessage(
        message: msg,
      );
    } finally {
      isSubmitting.value = false;
      isUploadingFiles.value = false;
    }
  }

  // NEW: Reset form helper
  void _resetForm() {
    selectedInvoice.value = null;
    selectedStage.value = null;
    clearAllFiles();
    brNumber.value = '';
  }
}
