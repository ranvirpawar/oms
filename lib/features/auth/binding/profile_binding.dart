import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/bindings_interface.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import '../controller/profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    // Always wipe any stale instance from a previous session before creating
    // a new one. ProfileController now loads user data from AuthManager in
    // onInit() — no navigation arguments needed.
    Get.delete<ProfileController>(force: true);

    Get.lazyPut<ProfileController>(
      () => ProfileController(),
      fenix: true,
    );
  }
}
