import 'package:get/get.dart';

import '../controller/patient_queue_controller.dart';
import '../service/patient_queue_service.dart';


class PatientQueueBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PatientQueueService>(() => PatientQueueService());
    Get.lazyPut<PatientQueueController>(
      () => PatientQueueController(service: Get.find<PatientQueueService>()),
    );
  }
}
