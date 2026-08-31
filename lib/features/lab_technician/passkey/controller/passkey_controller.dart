

// Controller

import '../model/passkey_model.dart';
import '../service/passkey_service.dart';
import 'package:get/get.dart';

class PasskeyController extends GetxController {
  final PasskeyService _service = PasskeyService();
  var passkeyData = Rx<PasskeyData?>(null);
  var isLoading = false.obs;
  var error = ''.obs;

  Future<void> fetchPasskey(String userId) async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await _service.getPassKey(userId);
      passkeyData.value = response.output.isNotEmpty ? response.output[0] : null;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
