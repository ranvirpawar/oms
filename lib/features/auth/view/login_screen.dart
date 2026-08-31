import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lifenity_connect/constants/app_assets.dart';
import 'package:lifenity_connect/features/auth/view/forgot_password_view.dart';
import 'package:lifenity_connect/services/app_envirionment_service.dart';
import '../../../componenents/app_textformfeild.dart';
import '../../../constants/app_strings.dart';

// login_controller.dart
import 'package:get/get.dart';

import '../../../theme/app_colors.dart';
import '../controller/login_controller.dart';

class LoginScreenView extends StatelessWidget {
  const LoginScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    final LoginController controller = Get.put(LoginController());

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),

          // App logo
          Flexible(
            flex: 2,
            child: Center(
              child: Image.asset(
                AppAssets.lifenityLogo,
                fit: BoxFit.contain,
                width: MediaQuery.of(context).size.width * 0.6,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Login card
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(40),
                  topLeft: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: controller.formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [

                        // Beta dropdown — only on beta builds
                        if (AppEnvironment.isBeta)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withOpacity(0.3)),
                            ),
                            child: Obx(() => DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                dropdownColor: AppColors.primary,
                                borderRadius: BorderRadius.circular(16),
                                hint: const Text(
                                  'Select Beta User (Auto-Fill)',
                                  style: TextStyle(color: Colors.white70, fontSize: 14),
                                ),
                                value: controller.selectedBetaUser.value,
                                icon: const Icon(Icons.bug_report, color: Colors.white70),
                                style: const TextStyle(color: Colors.white),
                                items: controller.betaUsers.entries.map((entry) {
                                  final String role = entry.key.trim();
                                  final String phone = entry.value['user']!;
                                  return DropdownMenuItem<String>(
                                    value: role,
                                    child: Text(
                                      '$role – $phone',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) => controller.fillBetaCredentials(val),
                              ),
                            )),
                          ),

                        const SizedBox(height: 12),

                        // Welcome back text
                        const Text(
                          AppStrings.welcomeBack,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Credentials section — fresh fields or welcome-back banner
                        Obx(() {
                          if (!controller.isReturningUser.value) {
                            return Column(
                              children: [
                                CustomTextFormField(
                                  controller: controller.emailController,
                                  hintText: AppStrings.userName,
                                  svgAssetPath: AppAssets.userIcon,
                                  validator: controller.validateUserName,
                                  keyboardType: TextInputType.text,
                                  cursorColor: Colors.white,
                                ),
                                const SizedBox(height: 16),
                                Obx(() => CustomTextFormField(
                                  controller: controller.passwordController,
                                  cursorColor: Colors.white,
                                  hintText: AppStrings.password,
                                  svgAssetPath: AppAssets.lockIcons,
                                  validator: controller.validatePassword,
                                  isPassword: true,
                                  isPasswordVisible: controller.isPasswordVisible.value,
                                  onTogglePassword: controller.togglePasswordVisibility,
                                )),
                              ],
                            );
                          }
                          return _WelcomeBackBanner(
                            username: controller.savedUsername.value,
                            onSwitch: controller.signInWithDifferent,
                          );
                        }),

                        const SizedBox(height: 16),

                        // Math verification
                        Obx(() => Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    AppAssets.questionIcon,
                                    height: 22,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Solve to continue',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: controller.generateMathProblem,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.refresh,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${controller.num1.value} ${controller.operator.value} ${controller.num2.value} = ?',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: controller.mathAnswerController,
                                      keyboardType: TextInputType.number,
                                      validator: controller.validateMathAnswer,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Answer',
                                        hintStyle: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 14,
                                        ),
                                        filled: true,
                                        fillColor: Colors.white.withOpacity(0.1),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.white.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.white.withOpacity(0.3),
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Colors.redAccent,
                                            width: 1,
                                          ),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Colors.redAccent,
                                            width: 2,
                                          ),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )),

                        const SizedBox(height: 24),

                        // Login button
                        Obx(() => SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: controller.isLoading.value
                                ? null
                                : controller.login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: controller.isLoading.value
                                ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                                strokeWidth: 2,
                              ),
                            )
                                : const Text(
                              AppStrings.login,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                              ),
                            ),
                          ),
                        )),

                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Get.to(() => const ForgotPasswordView()),
                            style: TextButton.styleFrom(
                              overlayColor: Colors.white,
                            ),
                            child: const Text(
                              AppStrings.forgotPassword,
                              style: TextStyle(color: AppColors.surface),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeBackBanner extends StatelessWidget {
  final String username;
  final VoidCallback onSwitch;

  const _WelcomeBackBanner({
    required this.username,
    required this.onSwitch,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
      ),
      child: Column(
        children: [
          // Username card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.person_outline, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back 👋',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        username,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Session expired pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.lock_open_rounded, color: Colors.white, size: 13),
                SizedBox(width: 8),
                Text(
                  'Session expired \nYou just need to solve problem to continue',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Sign in with different account
          GestureDetector(
            onTap: onSwitch,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.switch_account_outlined, color: Colors.white70, size: 13),
                  SizedBox(width: 4),
                  Text(
                    'Or sign in with a different account',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


