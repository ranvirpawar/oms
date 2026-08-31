// // lib/controllers/accept_bag_controller.dart
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:lifenity_connect/features/lab_technician/accept_handover_bag/service/lab_accession_api_service_old.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:lifenity_connect/features/lab_technician/accept_handover_bag/model/bag_model.dart';
//
// import '../../../../services/location_service.dart';
// import '../../../../services/snackbar_service.dart';
// import '../../../../services/user_service.dart';
// import '../../../auth/model/login_response_model.dart';
// class AcceptBagInLabController extends GetxController {
//   final LabAccessionService _apiService = LabAccessionService();
//   final LocationService _locationService = LocationService();
//
//   // Scanner Controller
//   late MobileScannerController scannerController;
//   final TextEditingController manualBarcodeController = TextEditingController();
//   // Observable variables
//   final scannedBarcode = Rx<String?>(null);
//   final bagDetails = Rx<BagDetail?>(null);
//   final isLoading = false.obs;
//   final isSubmitting = false.obs;
//   final scannerActive = true.obs;
//   final flashlightEnabled = false.obs;
//
//   // User ID
//   final Rx<UserModel?> user = Rx<UserModel?>(null);
//   final Rx<String> userId = ''.obs;
//   final UserService userService = Get.put(UserService());
//
//   @override
//   void onInit() {
//     super.onInit();
//     scannerController = MobileScannerController(
//       detectionSpeed: DetectionSpeed.unrestricted,
//       facing: CameraFacing.back,
//       torchEnabled: false,
//     );
//     debugPrint('✨ [Controller] AcceptBagInLabController Initialized.');
//   }
//
//   @override
//   void onClose() {
//     scannerController.dispose();
//     manualBarcodeController.dispose();
//     debugPrint('🗑️ [Controller] AcceptBagInLabController Disposed.');
//     super.onClose();
//   }
//
//   void loadUser() async {
//     try {
//       final userData = await userService.getUser();
//       if (userData != null) {
//         user.value = userData;
//         userId.value = user.value?.empCode.toString() ?? '';
//
//         debugPrint('✅ [Controller] User data loaded: ${user.value?.name}');
//       } else {
//         debugPrint('❌ [Controller] Failed to load user data');
//       }
//     } catch (e) {
//       debugPrint('❌ [Controller] Error loading user: $e');
//     }
//   }
//
//   // Toggle flashlight
//   void toggleFlashlight() {
//     flashlightEnabled.value = !flashlightEnabled.value;
//     scannerController.toggleTorch();
//     debugPrint('🔦 [Scanner] Flashlight Toggled: ${flashlightEnabled.value}');
//   }
//
//   // Handle barcode scan
//   void onBarcodeDetected(BarcodeCapture capture) async {
//     if (!scannerActive.value || isLoading.value) return;
//
//     final List<Barcode> barcodes = capture.barcodes;
//     if (barcodes.isEmpty) return;
//
//     final barcode = barcodes.first.rawValue;
//     if (barcode == null || barcode.isEmpty) return;
//
//     // Stop scanning temporarily
//     scannerActive.value = false;
//     scannedBarcode.value = barcode;
//     debugPrint('🔍 [Scanner] Barcode detected, pausing scanner: $barcode');
//
//     // Fetch bag details
//     await fetchBagDetails(barcode);
//   }
//
//   void onManualBarcodeSubmit(String barcode) {
//     debugPrint('⌨️ [Scanner] Manual barcode submitted: $barcode');
//     // Reuse the same logic as scanner detection
//     fetchBagDetails(barcode);
//   }
//
//   // Fetch bag details from API
//   Future<void> fetchBagDetails(String bagcode) async {
//     isLoading.value = true;
//     bagDetails.value = null; // Clear previous details
//     debugPrint('⚙️ [API] Starting fetchBagDetails for Bagcode: $bagcode');
//
//     try {
//       final String processId = '9'; // Process ID for accepting bag
//
//       debugPrint('📤 [API] Calling getScanQRForAndTransactionID (P-$processId) for user: ${userId.value}');
//
//       final response = await _apiService.getScanQRForAndTransactionID(
//         bagcode: bagcode,
//         processid: processId,
//         userid: userId.value,
//       );
//
//       if (response.status == 'Success' && response.output != null && response.output!.isNotEmpty) {
//         bagDetails.value = response.output!.first;
//         debugPrint('✅ [API] Details fetched successfully. TransactionID: ${bagDetails.value!.transactionID}');
//         Get.snackbar(
//           'Success',
//           'Bag scanned successfully',
//           backgroundColor: Colors.green.withOpacity(0.8),
//           colorText: Colors.white,
//           snackPosition: SnackPosition.TOP,
//           duration: const Duration(seconds: 2),
//         );
//       } else {
//         final String errorMessage = response.message.isNotEmpty
//             ? response.message
//             : 'Bag can not be collected ';
//
//         debugPrint('⚠️ [API] Failed response status: ${response.status}. Message: $errorMessage');
//
//         // Throw an exception so the catch block handles the error message and resets the scanner
//         SnackBarService.to.showMessage(message: errorMessage);
//         Future.delayed(const Duration(seconds: 4), () {
//           resetScanner();} );
//       }
//     } catch (e) {
//       debugPrint('❌ [API] Error fetching bag details: $e');
//       Get.snackbar(
//         'Error',
//         'Failed to fetch bag details: $e',
//         backgroundColor: Colors.red.withOpacity(0.8),
//         colorText: Colors.white,
//         snackPosition: SnackPosition.TOP,
//       );
//       resetScanner();
//     } finally {
//       isLoading.value = false;
//       debugPrint('⏳ [State] isLoading set to ${isLoading.value}');
//     }
//   }
//
//   // Submit and accept bag
//   Future<void> acceptBag() async {
//     if (bagDetails.value == null) {
//       debugPrint('🚫 [Validation] Cannot accept bag. bagDetails is null.');
//       Get.snackbar(
//         'Error',
//         'Please scan a bag first',
//         backgroundColor: Colors.orange.withOpacity(0.8),
//         colorText: Colors.white,
//         snackPosition: SnackPosition.TOP,
//       );
//       return;
//     }
//
//     isSubmitting.value = true;
//     final String transactionId = bagDetails.value!.transactionID.toString();
//     final String processId = '14'; // Process ID for bag received
//
//     debugPrint('⚙️ [API] Starting acceptBag for TransactionID: $transactionId (P-$processId)');
//
//     try {
//       // Get current location
//       debugPrint('📍 [Location] Fetching current location...');
//       final location = await _locationService.getLocationStrings();
//       debugPrint('📍 [Location] Fetched: Lat=${location['latitude']}, Long=${location['longitude']}');
//
//       // Submit status update
//       debugPrint('📤 [API] Calling insertBagTransactionStatus...');
//       final response = await _apiService.insertBagTransactionStatus(
//         transactionID: transactionId,
//         processid: processId,
//         userid: userId.value,
//         lats: location['latitude']!,
//         longs: location['longitude']!,
//         handOverUserid: userId.value,
//       );
//
//       if (response.status == 'Success') {
//         debugPrint('🎉 [API] Bag successfully accepted and status updated!');
//         Get.snackbar(
//           'Success',
//           'Bag accepted successfully!',
//           backgroundColor: Colors.green.withOpacity(0.8),
//           colorText: Colors.white,
//           snackPosition: SnackPosition.TOP,
//           duration: const Duration(seconds: 2),
//         );
//
//         // Reset for next scan
//         await Future.delayed(const Duration(seconds: 1));
//         resetScanner();
//       } else {
//         debugPrint('⚠️ [API] Status update failed. Message: ${response.message}');
//         throw Exception(response.message);
//       }
//     } catch (e) {
//       debugPrint('❌ [API] Error accepting bag: $e');
//       Get.snackbar(
//         'Error',
//         'Failed to accept bag: $e',
//         backgroundColor: Colors.red.withOpacity(0.8),
//         colorText: Colors.white,
//         snackPosition: SnackPosition.TOP,
//       );
//     } finally {
//       isSubmitting.value = false;
//       debugPrint('⏳ [State] isSubmitting set to ${isSubmitting.value}');
//     }
//   }
//
//   // Reset scanner
//   void resetScanner() {
//     scannedBarcode.value = null;
//     bagDetails.value = null;
//     scannerActive.value = true;
//     debugPrint('🔄 [State] Scanner reset and active.');
//   }
// }
//
