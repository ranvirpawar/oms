// profile_controller.dart
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/features/auth/model/profile_model.dart';
import 'package:lifenity_connect/services/auth_manager.dart';

class ProfileController extends GetxController {
  ProfileData user;
  final AuthManager authManager = Get.find<AuthManager>();

  // --- Controllers for all fields ---
  late final TextEditingController firstNameController;
  late final TextEditingController lastNameController;
  late final TextEditingController genderController; // will be used with radio
  late final TextEditingController roleController;
  late final TextEditingController phoneNumberController; // extra
  late final TextEditingController clinicController; // extra
  late final TextEditingController doctorController; // extra
  late final TextEditingController mobileNumberController;
  late final TextEditingController skillCategoryController; // extra
  late final TextEditingController dobController;
  late final TextEditingController emailController;
  late final TextEditingController streetController; // extra
  late final TextEditingController districtController;
  late final TextEditingController cityController;
  late final TextEditingController pinController;
  late final TextEditingController addressController;

  // For header
  late final TextEditingController nameController;
  late final TextEditingController empIdController;
  late final TextEditingController designationController; // from user.designation

  // Gender selection (used in UI)
  String selectedGender = '';

  final RxString age = ''.obs; // ← observable age

  ProfileController({required this.user}) {
    // Populate from user model
    firstNameController = TextEditingController(text: user.firstName);
    lastNameController = TextEditingController(text: user.lastName);
    selectedGender = user.gender;
    genderController = TextEditingController(text: user.gender);
    roleController = TextEditingController(text: user.designation);
    phoneNumberController = TextEditingController(); // extra, left empty
    clinicController = TextEditingController(); // extra
    doctorController = TextEditingController(); // extra
    mobileNumberController = TextEditingController(text: user.perMobile);
    skillCategoryController = TextEditingController(); // extra
    dobController = TextEditingController(text: user.dob);
    emailController = TextEditingController(text: user.perEmail);
    streetController = TextEditingController(); // extra
    districtController = TextEditingController(text: user.distName);
    cityController = TextEditingController(text: user.cityName);
    pinController = TextEditingController(text: user.zipCode);
    addressController = TextEditingController(text: user.cAddress);

    // Header
    nameController = TextEditingController(text: user.name);
    empIdController = TextEditingController(text: user.empCode.toString());
    designationController = TextEditingController(text: user.designation);

    // Listen to DOB changes
    dobController.addListener(() {
      age.value = _calculateAge(dobController.text);
    });
    // Set initial age
    age.value = _calculateAge(dobController.text);
  }

  @override
  void onClose() {
    firstNameController.dispose();
    lastNameController.dispose();
    genderController.dispose();
    roleController.dispose();
    phoneNumberController.dispose();
    clinicController.dispose();
    doctorController.dispose();
    mobileNumberController.dispose();
    skillCategoryController.dispose();
    dobController.dispose();
    emailController.dispose();
    streetController.dispose();
    districtController.dispose();
    cityController.dispose();
    pinController.dispose();
    addressController.dispose();
    nameController.dispose();
    empIdController.dispose();
    designationController.dispose();
    super.onClose();
  }

  // Save the updated data
  Future<void> saveProfile() async {
    final updatedUser = user.copyWith(
      firstName: firstNameController.text,
      lastName: lastNameController.text,
      gender: selectedGender.isNotEmpty ? selectedGender : genderController.text,
      designation: roleController.text,
      perMobile: mobileNumberController.text,
      dob: dobController.text,
      perEmail: emailController.text,
      distName: districtController.text,
      cityName: cityController.text,
      zipCode: pinController.text,
      cAddress: addressController.text,
      // If you later add more fields to the model, include them here
    );

    user = updatedUser;
    await authManager.saveUserProfileToStorage(user);
    Get.snackbar('Success', 'Profile updated successfully');
  }

  String _calculateAge(String dob) {
    if (dob.isEmpty) return '';
    try {
      final parts = dob.split('/');
      if (parts.length != 3) return '';
      final birth = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      final now = DateTime.now();
      int years = now.year - birth.year;
      if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) years--;
      return '$years Yrs';
    } catch (_) {
      return '';
    }
  }

  // Compute age from DOB (if needed)
  /*String getAge(String dob) {
    // Simple calculation – you can improve with proper date parsing
    if (dob.isEmpty) return '';
    try {
      final parts = dob.split('/');
      if (parts.length != 3) return '';
      final birth = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      final now = DateTime.now();
      int age = now.year - birth.year;
      if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      return '$age Yrs';
    } catch (_) {
      return '';
    }
  }*/
}
