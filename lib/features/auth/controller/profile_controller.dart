// profile_controller.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide SnackPosition;
import 'package:lifenity_connect/features/auth/model/profile_model.dart';
import 'package:lifenity_connect/features/auth/service/profile_service.dart';
import 'package:lifenity_connect/services/auth_manager.dart';
import 'package:lifenity_connect/utils/helper_functions/helper_methods.dart';
import 'package:lifenity_connect/utils/ui_designs/liquid_snackbar.dart';

class ProfileController extends GetxController {
  final AuthManager authManager = Get.find<AuthManager>();
  final ProfileService _profileService = ProfileService();

  // Current user — loaded fresh from AuthManager in onInit
  ProfileData? user;

  // --- Text controllers ---
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController genderController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController clinicController = TextEditingController();
  final TextEditingController doctorController = TextEditingController();
  final TextEditingController mobileNumberController = TextEditingController();
  final TextEditingController skillCategoryController = TextEditingController();
  final TextEditingController dobController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController districtController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController pinController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  // For header
  final TextEditingController nameController = TextEditingController();
  final TextEditingController empIdController = TextEditingController();
  final TextEditingController designationController = TextEditingController();

  // Gender selection
  String selectedGender = '';

  final RxString age = ''.obs;

  // Whether profile data has been loaded successfully
  final RxBool isLoading = true.obs;

  // ── OTP flow ────────────────────────────────────────────────────────────────
  final RxBool isMobileVerified = false.obs;
  final RxBool isOtpLoading = false.obs;
  final RxBool showOtpSection = false.obs;
  final RxString otpError = ''.obs;

  /// True after the new number has been verified via OTP — shows the
  /// green "Number verified" badge in the UI.
  final RxBool showVerifiedBadge = false.obs;

  final GlobalKey<dynamic> otpInputKey = GlobalKey();

  String _originalMobile = '';
  // ────────────────────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    _loadAndPopulate();
  }

  /// Loads the current session's profile from AuthManager (storage),
  /// then populates all text controllers.
  Future<void> _loadAndPopulate() async {
    isLoading.value = true;
    try {
      // Always fetch from storage — guaranteed to be the current session's user
      final profile = await authManager.getUserProfileFromStorage();
      if (profile == null) {
        kPrint('ProfileController: no profile in storage');
        return;
      }
      user = profile;
      _populateFields(profile);
    } catch (e) {
      kPrint('ProfileController._loadAndPopulate error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Fills every TextEditingController from [profile] and wires up listeners.
  void _populateFields(ProfileData profile) {
    firstNameController.text = profile.firstName;
    middleNameController.text = profile.middleName;
    lastNameController.text = profile.lastName;
    selectedGender = profile.gender;
    genderController.text = profile.gender;
    roleController.text = profile.designation;
    mobileNumberController.text = profile.perMobile;
    dobController.text = profile.dob;
    emailController.text = profile.perEmail;
    districtController.text = profile.distName;
    cityController.text = profile.cityName;
    pinController.text = profile.zipCode;
    addressController.text = profile.cAddress;

    // Header
    final resolvedName = profile.name.isNotEmpty
        ? profile.name
        : '${profile.firstName} ${profile.middleName} ${profile.lastName}'
              .trim();
    nameController.text = resolvedName.isNotEmpty
        ? resolvedName
        : profile.username;
    empIdController.text = profile.empCode.toString();
    designationController.text = profile.designation;

    // Track original mobile — current value is already saved → allow save.
    _originalMobile = profile.perMobile;
    isMobileVerified.value = true;

    // DOB → age
    age.value = _calculateAge(dobController.text);
    dobController.addListener(() {
      age.value = _calculateAge(dobController.text);
    });

    // Mobile changes → OTP flow
    mobileNumberController.addListener(_onMobileChanged);

    // First/Middle/Last → keep display-only Name field in sync
    firstNameController.addListener(_syncDisplayName);
    middleNameController.addListener(_syncDisplayName);
    lastNameController.addListener(_syncDisplayName);
  }

  // ── Name sync ────────────────────────────────────────────────────────────────

  void _syncDisplayName() {
    final parts = [
      firstNameController.text.trim(),
      middleNameController.text.trim(),
      lastNameController.text.trim(),
    ].where((p) => p.isNotEmpty).join(' ');
    nameController.text = parts;
  }

  // ── OTP helpers ─────────────────────────────────────────────────────────────

  void _onMobileChanged() {
    final newNumber = mobileNumberController.text.trim();

    // Number restored to the original session value — no OTP needed.
    if (newNumber == _originalMobile) {
      isMobileVerified.value = true;
      showOtpSection.value = false;
      showVerifiedBadge.value = false;
      otpError.value = '';
      return;
    }

    // Number changed — require fresh verification.
    isMobileVerified.value = false;
    showVerifiedBadge.value = false;
    otpError.value = '';

    // Only trigger OTP when a complete 10-digit number is entered.
    if (newNumber.length == 10) {
      sendOtp();
    } else {
      // Still typing — hide OTP section until full number is ready.
      showOtpSection.value = false;
    }
  }

  Future<void> sendOtp() async {
    final newNumber = mobileNumberController.text.trim();
    if (newNumber.length != 10) return;
    if (user == null) return;

    isOtpLoading.value = true;
    otpError.value = '';

    try {
      final success = await _profileService.sendProfileUpdateOtp(
        userId: user!.empCode,
        newMobileNo: newNumber,
      );
      if (success) {
        showOtpSection.value = true;
        otpInputKey.currentState?.clear();
      }
    } catch (e) {
      kPrint('sendOtp error: $e');
    } finally {
      isOtpLoading.value = false;
    }
  }

  Future<void> verifyOtp(String otp) async {
    if (otp.length != 4) return;
    if (user == null) return;

    isOtpLoading.value = true;
    otpError.value = '';

    try {
      final success = await _profileService.verifyProfileUpdateOtp(
        userId: user!.empCode,
        mobileNo: mobileNumberController.text.trim(),
        otp: otp,
      );
      if (success) {
        isMobileVerified.value = true;
        showOtpSection.value = false;
        showVerifiedBadge.value = true;
      } else {
        otpError.value = 'Incorrect OTP. Please try again.';
      }
    } catch (e) {
      kPrint('verifyOtp error: $e');
      otpError.value = 'Verification failed. Please try again.';
    } finally {
      isOtpLoading.value = false;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────

  @override
  void onClose() {
    // TextEditingControllers are intentionally NOT disposed here.
    // With fenix:true the controller (and its fields) is recreated fresh on
    // every navigation; the old instance is garbage-collected by Dart.
    // Disposing here causes "used after being disposed" crashes because
    // Flutter's pop animation may render one more frame after onClose fires.
    super.onClose();
  }

  // Save the updated data via UpdateUserProfile API
  Future<void> saveProfile() async {
    if (user == null) return;

    final firstName = firstNameController.text.trim();
    final midName = middleNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final newMobileNo = mobileNumberController.text.trim();

    // Check if the mobile number was changed or differs from saved session credentials
    final savedCreds = await authManager.getSavedCredentials();
    final bool isNumberChanged =
        (newMobileNo.isNotEmpty && newMobileNo != _originalMobile) ||
        (savedCreds != null && savedCreds.username != newMobileNo);

    try {
      final success = await _profileService.updateUserProfile(
        userId: user!.empCode,
        firstName: firstName,
        midName: midName,
        lastName: lastName,
        newMobileNo: newMobileNo,
      );

      if (!success) return;

      final fullName = [
        firstName,
        midName,
        lastName,
      ].where((p) => p.isNotEmpty).join(' ');

      final updatedUser = user!.copyWith(
        name: fullName.isNotEmpty ? fullName : user!.name,
        firstName: firstName,
        middleName: midName,
        lastName: lastName,
        perMobile: newMobileNo,
        gender: selectedGender.isNotEmpty
            ? selectedGender
            : genderController.text,
        designation: designationController.text.isNotEmpty
            ? designationController.text
            : roleController.text,
        dob: dobController.text,
        perEmail: emailController.text,
        distName: districtController.text.trim(),
        cityName: cityController.text,
        zipCode: pinController.text,
        cAddress: addressController.text,
      );

      user = updatedUser;
      _originalMobile = newMobileNo;
      nameController.text = fullName.isNotEmpty ? fullName : user!.name;
      await authManager.saveUserProfileToStorage(user!);

      LiquidSnack.success(
        'Profile updated successfully. Please log in again.',
        title: 'Success',
      );

      // Give the snackbar a moment to display before logging out.
      await Future.delayed(const Duration(seconds: 2));

      // If mobile number was updated, wipe saved credentials so the previous
      // number is cleared and login starts completely fresh.
      if (isNumberChanged) {
        await authManager.clearSavedCredentials();
      }
      await authManager.logoutUser(clearCredentials: isNumberChanged);
    } catch (e) {
      kPrint('saveProfile error: $e');
      LiquidSnack.error('Failed to update profile. Please try again.');
    }
  }

  String _calculateAge(String dob) {
    if (dob.isEmpty) return '';
    try {
      final parts = dob.split('/');
      if (parts.length != 3) return '';
      final birth = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
      final now = DateTime.now();
      int years = now.year - birth.year;
      if (now.month < birth.month ||
          (now.month == birth.month && now.day < birth.day)) {
        years--;
      }
      return '$years Yrs';
    } catch (_) {
      return '';
    }
  }
}
