import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/features/auth/model/profile_model.dart';
import 'package:lifenity_connect/services/auth_manager.dart';

class ProfileController extends GetxController {
  ProfileData user; // not final, so we can reassign
  final AuthManager authManager = Get.find<AuthManager>();

  late final TextEditingController nameController;
  late final TextEditingController empIdController;
  late final TextEditingController phoneController;
  late final TextEditingController emailController;
  late final TextEditingController districtController;
  late final TextEditingController cityController;
  late final TextEditingController pinController;
  late final TextEditingController addressController;

  ProfileController({required this.user}) {
    nameController = TextEditingController(text: user.name);
    empIdController = TextEditingController(text: user.empCode.toString()); // int → String
    phoneController = TextEditingController(text: user.perMobile);
    emailController = TextEditingController(text: user.perEmail);
    districtController = TextEditingController(text: user.distName);
    cityController = TextEditingController(text: user.cityName);
    pinController = TextEditingController(text: user.zipCode);
    addressController = TextEditingController(text: user.cAddress); // or user.pAddress
  }

  @override
  void onClose() {
    nameController.dispose();
    empIdController.dispose();
    phoneController.dispose();
    emailController.dispose();
    districtController.dispose();
    cityController.dispose();
    pinController.dispose();
    addressController.dispose();
    super.onClose();
  }

  Future<void> saveProfile() async {
    final updatedUser = user.copyWith(
      name: nameController.text,
      perMobile: phoneController.text,
      perEmail: emailController.text,
      distName: districtController.text,
      cityName: cityController.text,
      zipCode: pinController.text,
      cAddress: addressController.text,
      // Note: empCode is not editable in the UI, so we don't update it.
    );

    user = updatedUser;

    // Persist via AuthManager (make sure this method saves the full object)
    await authManager.saveUserProfileToStorage(user);

    Get.snackbar('Success', 'Profile updated successfully');
  }
}
