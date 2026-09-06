
import 'package:get/get.dart';

import '../../patient_queue/model/patient_queue_model.dart';
import '../controller/sample_collection_controller.dart';

class SampleCollectionBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments as Map?;
    final assignedPatient = args?['assignedPatient'] as AssignedPatient?;

    assert(assignedPatient != null,
    'SampleCollectionBinding requires an AssignedPatient in arguments');

    Get.lazyPut<SampleCollectionController>(
          () => SampleCollectionController(assignedPatient: assignedPatient!),
    );
  }
}
