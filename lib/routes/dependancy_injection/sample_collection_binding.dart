// sample_collection_binding.dart
//
// Wire this into your route table, e.g.:
//
//   GetPage(
//     name: AppRoutes.sampleCollection,
//     page: () => const OrderConfirmationScreen(),
//     binding: SampleCollectionBinding(),
//   ),
//
// Navigate from PatientCard's onPrimaryAction / onTapDetails (or wherever
// "Start Route" / collection kicks off) with:
//
//   Get.toNamed(AppRoutes.sampleCollection, arguments: {'orderId': patient.orderId});
//
// orderId is required. If you pass userId explicitly it's used as-is;
// otherwise the controller resolves EmpCode itself via AuthManager
// (see SampleCollectionController._loadEmpId), matching the snippet you
// shared (authManager.getUserData() -> user['EmpCode']).

import 'package:get/get.dart';

import '../../features/phlebotomist/sample_collection/controller/sample_collection_controller.dart';

class SampleCollectionBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments as Map?;
    final orderId = args?['orderId']?.toString() ?? '';

    Get.lazyPut<SampleCollectionController>(
      () => SampleCollectionController(orderId: orderId),
    );
  }
}
