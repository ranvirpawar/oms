import 'package:get/get.dart';

import '../controller/patient_queue_controller.dart';
import '../service/patient_queue_service.dart';


class PatientQueueBinding extends Bindings {
  @override
  void dependencies() {
    // Mirrors SampleCollectionBinding: navigation arguments are resolved
    // here and constructor-injected into the controller. Collection mode
    // is set by RouteManager.navigateToPatientQueue(isCollectionTrue: true)
    // (bag registration dashboard's Collect action).
    final args = Get.arguments as Map?;
    final isCollectionMode = args?['isCollectionMode'] == true;

    Get.lazyPut<PatientQueueService>(() => PatientQueueService());
    Get.lazyPut<PatientQueueController>(
      () => PatientQueueController(
        service: Get.find<PatientQueueService>(),
        isCollectionMode: isCollectionMode,
      ),
    );
  }
}
