import 'package:get/get.dart';

import '../controller/login_controller.dart';
import '../service/login_service.dart';

/// Registers the dependencies required by the login screen and login controller.
/// Pass it to any navigation that opens the login flow:
///
/// ```dart
/// Get.offAll(() => const LoginScreenView(), binding: LoginBinding());
/// ```
///
/// Mirror of the existing feature bindings in this folder
/// (`PatientQueueBinding`, `SampleCollectionBinding`).
class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginService>(() => LoginService());
    Get.lazyPut<LoginController>(() => LoginController());
  }
}