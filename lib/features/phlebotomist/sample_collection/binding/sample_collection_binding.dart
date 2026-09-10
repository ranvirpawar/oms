// sample_collection_bindings.dart
//
// One binding per screen in this flow. Each creates its controller with
// plain, non-nullable constructor arguments — no `Get.arguments as Map?`
// casting. A missing patient is now a compile error at the call site
// instead of a runtime null-cast crash inside the binding.

import 'package:get/get.dart';

import '../../patient_queue/model/patient_queue_model.dart';
import '../controller/order_confirmation_controller.dart';
import '../controller/sample_collection_controller.dart';

class OrderConfirmationBinding extends Bindings {
  OrderConfirmationBinding(this.assignedPatient);

  final AssignedPatient assignedPatient;

  @override
  void dependencies() {
    Get.lazyPut<OrderConfirmationController>(
          () => OrderConfirmationController(assignedPatient: assignedPatient),
    );
  }
}

class SampleCollectionBinding extends Bindings {
  SampleCollectionBinding({
    required this.orderId,
    required this.assignedPatient,
  });

  final String orderId;
  final AssignedPatient assignedPatient;

  @override
  void dependencies() {
    Get.lazyPut<SampleCollectionController>(
          () => SampleCollectionController(
        orderId: orderId,
        assignedPatient: assignedPatient,
      ),
    );
  }
}