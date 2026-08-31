// import 'package:flutter/cupertino.dart';
// import 'package:lifenity_connect/features/auth/model/login_response_model.dart';
// import 'package:lifenity_connect/services/snackbar_service.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
//
// import '../../../../componenents/success_checked_animation_dialouge.dart';
// import '../../../../componenents/success_dialog.dart';
// import '../../../../routes/route_manager.dart';
// import '../../../../services/user_service.dart';
// import 'package:get/get.dart';
//
// // controllers/collect_empty_bag_controller.dart
//
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';
//
// import '../model/bag_detail_model.dart';
// import '../service/bag_service.dart';
// enum CollectionReason { handoverToPhlebotomist, collectSample }
//
// class CollectEmptyBagController extends GetxController {
//   final UserService userService = Get.find();
//   final BagService bagService = BagService();
//   final FocusNode manualInputFocusNode = FocusNode();
//   final RxBool isManualInputActive = false.obs;
//
//   late MobileScannerController scannerController;
//   final TextEditingController manualBarcodeController = TextEditingController();
//
//   final Rx<UserModel?> user = Rx<UserModel?>(null);
//   final RxString userId = ''.obs;
//   final collectionReason = CollectionReason.handoverToPhlebotomist.obs;
//
//   // State
//   final RxBool isLoading = false.obs;
//   final RxBool isSubmitting = false.obs;
//   final RxBool scannerActive = true.obs;
//   final RxBool flashlightEnabled = false.obs;
//
//   final Rx<BagDetail?> bagDetail = Rx<BagDetail?>(null);
//   final RxString scannedBarcode = ''.obs;
//
//   @override
//   void onInit() {
//     super.onInit();
//     loadUser();
//     scannerController = MobileScannerController(
//       detectionSpeed: DetectionSpeed.unrestricted,
//       facing: CameraFacing.back,
//     );
//     manualInputFocusNode.addListener(() {
//       isManualInputActive.value = manualInputFocusNode.hasFocus;
//     });
//   }
//
//   @override
//   void onClose() {
//     scannerController.dispose();
//     manualBarcodeController.dispose();
//     manualInputFocusNode.dispose();
//     super.onClose();
//
//   }
//
//   Future<void> loadUser() async {
//     try {
//       final userData = await userService.getUser();
//       if (userData != null) {
//         user.value = userData;
//         userId.value = userData.empCode.toString();
//       }
//     } catch (e) {
//       debugPrint('User load error: $e');
//     }
//   }
//
//   void toggleFlashlight() {
//     flashlightEnabled.value = !flashlightEnabled.value;
//     scannerController.toggleTorch();
//   }
//
//   // Only fetch bag details on scan
//   void onBarcodeDetected(BarcodeCapture capture) async {
//     if (!scannerActive.value || isLoading.value) return;
//
//     final barcode = capture.barcodes.firstOrNull?.rawValue;
//     if (barcode == null || barcode.isEmpty) return;
//
//     scannerActive.value = false;
//     scannedBarcode.value = barcode;
//     manualBarcodeController.text = barcode;
//
//     await fetchBagDetails(barcode);
//   }
//
//   void onManualSubmit() async {
//     final barcode = manualBarcodeController.text.trim();
//     if (barcode.isEmpty) {
//       SnackBarService.to.showMessage(message: 'Enter a valid barcode');
//       return;
//     }
//     scannerActive.value = false;
//     scannedBarcode.value = barcode;
//     await fetchBagDetails(barcode);
//   }
//
//   // Only fetch details — NO transaction yet
//   Future<void> fetchBagDetails(String barcode) async {
//     isLoading.value = true;
//     bagDetail.value = null;
//
//     try {
//       final response = await bagService.getBagDetails(barcode);
//
//       if (!response.isSuccess || response.output?.isEmpty == true) {
//         throw Exception(response.message.isNotEmpty ? response.message : 'Bag not found');
//       }
//
//       bagDetail.value = response.output!.first;
//
//       Get.snackbar('Success', 'Bag scanned successfully',
//           backgroundColor: Colors.green.withOpacity(0.8),
//           colorText: Colors.white,
//           duration: const Duration(seconds: 2));
//     } catch (e) {
//       String msg = e.toString().replaceAll('Exception: ', '');
//       SnackBarService.to.showMessage(message: msg.isEmpty ? 'Invalid bag' : msg);
//       Future.delayed(const Duration(seconds: 3), resetScanner);
//     } finally {
//       isLoading.value = false;
//     }
//   }
//
//   // This is called only when user presses "Collect Bag"
//   Future<void> collectBag() async {
//     if (bagDetail.value == null) {
//       Get.snackbar('Error', 'Please scan a bag first');
//       return;
//     }
//
//     isSubmitting.value = true;
//
//     try {
//       final processId = collectionReason.value == CollectionReason.handoverToPhlebotomist ? 1 : 5;
//
//       // Step 1: Insert Initial Transaction
//       final initResp = await bagService.insertInitialTransaction(
//         bagId: bagDetail.value!.bagId,
//         processId: processId,
//         userId: int.parse(userId.value),
//         transactionId: 0,
//       );
//
//       if (!initResp.isSuccess || initResp.transactionId == null) {
//         SnackBarService.to.showMessage(message: "This bag can not be collected", duration: const Duration(seconds: 2));
//         resetScanner();
//         return;
//       }
//
//       final transactionId = initResp.transactionId!;
//
//
//
//       final statusResp = await bagService.insertBagTransactionStatus(
//         transactionId: transactionId,
//         processId: processId,
//         userId: int.parse(userId.value),
//         handOverUserId: int.parse(userId.value),
//
//       );
//
//       if (!statusResp.isSuccess) {
//         throw Exception(statusResp.message ?? 'Failed to update status');
//       }
//
//
//       Get.dialog(
//         ModernSuccessDialog(
//           message: "Bag Collected Successfully",
//           buttonText: "OK",
//           onPressed: () {
//             Get.back();
//             RouteManager.redirectToHomeDashboard();
//           },
//         ),
//         barrierDismissible: false,
//       );
//
//
//
//
//       await Future.delayed(const Duration(seconds: 1));
//       resetScanner();
//     } catch (e) {
//       String msg = e.toString().replaceAll('Exception: ', '');
//       SnackBarService.to.showMessage(message: msg.isEmpty ? 'Collection failed' : msg);
//     } finally {
//       isSubmitting.value = false;
//     }
//   }
//
//   void resetScanner() {
//     bagDetail.value = null;
//     scannedBarcode.value = '';
//     manualBarcodeController.clear();
//     scannerActive.value = true;
//   }
// }
//
