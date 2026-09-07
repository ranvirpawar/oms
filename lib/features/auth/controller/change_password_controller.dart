import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../services/auth_manager.dart';
import '../../../utils/ui_designs/liquid_snackbar.dart';
import '../../dashboard/controller/user_model.dart';
import '../service/change_password_service.dart';


class ChangePasswordController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool isOldPasswordVisible = false.obs;
  final RxBool isNewPasswordVisible = false.obs;
  final RxBool isConfirmPasswordVisible = false.obs;

  final AuthManager _authManager = Get.find<AuthManager>();
  final ChangePasswordService _changePasswordService =
      Get.put(ChangePasswordService());

  String? _empCode;

  @override
  void onInit() {
    super.onInit();
    _loadEmpCode();
  }

  @override
  void onClose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  // ─── Load logged-in user's EmpCode ───────────────────────────────────────

  Future<void> _loadEmpCode() async {
    try {
      final data = await _authManager.getUserData();
      if (data == null) return;

      final userMap = data['user'];
      if (userMap == null || userMap is! Map<String, dynamic>) return;

      final user = UserModel.fromMap(userMap);

      _empCode = user.empCode.toString();

      debugPrint('✅ ChangePasswordController — EmpCode: $_empCode');
    } catch (e) {
      debugPrint('❌ _loadEmpCode: $e');
    }
  }

  // ─── Validators ──────────────────────────────────────────────────────────

  String? validateOldPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Current password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'New password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    if (value == oldPasswordController.text) {
      return 'New password must differ from current password';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your new password';
    }
    if (value != newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // ─── Submit ───────────────────────────────────────────────────────────────

  Future<void> changePassword() async {
    if (!formKey.currentState!.validate()) return;

    if (_empCode == null) {
      LiquidSnack.error('Unable to identify user. Please re-login.');
      return;
    }

    try {
      isLoading.value = true;

      final success = await _changePasswordService.changePassword(
        empCode: _empCode!,
        oldPassword: oldPasswordController.text.trim(),
        newPassword: newPasswordController.text.trim(),
      );

      if (success) {


        Get.back();

        LiquidSnack.success('Password updated successfully');
      }
    } catch (_) {
      // Error already shown by service
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Visibility toggles ───────────────────────────────────────────────────

  void toggleOldPasswordVisibility() =>
      isOldPasswordVisible.value = !isOldPasswordVisible.value;

  void toggleNewPasswordVisibility() =>
      isNewPasswordVisible.value = !isNewPasswordVisible.value;

  void toggleConfirmPasswordVisibility() =>
      isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
}
