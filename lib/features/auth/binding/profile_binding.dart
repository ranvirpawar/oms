import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/bindings_interface.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:lifenity_connect/features/auth/model/login_response_model.dart';
import 'package:lifenity_connect/features/auth/model/profile_model.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    final args = Get.arguments as Map?;
    final user = args?['loggedInUser'] as ProfileData?;

    assert(user != null, 'ProfileBinding requires an loggedInUser in arguments');

    /*Get.lazyPut<SampleCollectionController>(
          () => SampleCollectionController(assignedPatient: assignedPatient!),
    );*/
  }
}
