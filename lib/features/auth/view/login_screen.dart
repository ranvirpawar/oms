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
      resizeToAvoidBottomInset: true,
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
                child: SingleChildScrollView(
                  child: Obx(() {
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        final offsetAnim = Tween<Offset>(
                          begin: const Offset(0.08, 0),
                          end: Offset.zero,
                        ).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(position: offsetAnim, child: child),
                        );
                      },
                      child: controller.currentStep.value == LoginStep.credentials
                          ? _CredentialsStep(
                        key: const ValueKey('credentials'),
                        controller: controller,
                      )
                          : _OtpStep(
                        key: const ValueKey('otp'),
                        controller: controller,
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================================
// STEP 1 — credentials
// ======================================================================
class _CredentialsStep extends StatelessWidget {
  final LoginController controller;
  const _CredentialsStep({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.formKey,
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
              return AutofillGroup(
                child: Column(
                  children: [
                    CustomTextFormField(
                      controller: controller.emailController,
                      hintText: AppStrings.userName,
                      svgAssetPath: AppAssets.userIcon,
                      validator: controller.validateUserName,
                      keyboardType: TextInputType.text,
                      cursorColor: Colors.white,

                      // autofillHints: const [AutofillHints.username],
                      // textInputAction: TextInputAction.next,
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
                      // autofillHints: const [AutofillHints.password],
                      // textInputAction: TextInputAction.done,
                      // onFieldSubmitted: (_) => controller.requestOtp(),
                    )),
                  ],
                ),
              );
            }
            return _WelcomeBackBanner(
              username: controller.savedUsername.value,
              onSwitch: controller.signInWithDifferent,
            );
          }),

          const SizedBox(height: 28),

          // Continue button — sends OTP
          Obx(() => SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: controller.isLoading.value ? null : controller.requestOtp,
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
                'CONTINUE',
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
              style: TextButton.styleFrom(overlayColor: Colors.white),
              child: const Text(
                AppStrings.forgotPassword,
                style: TextStyle(color: AppColors.surface),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ======================================================================
// STEP 2 — OTP
// ======================================================================
class _OtpStep extends StatelessWidget {
  final LoginController controller;
  const _OtpStep({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.sms_outlined, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 16),
        const Text(
          'Verify it\'s you',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 6),
        Obx(() => Text(
          controller.maskedMobile.value.isNotEmpty
              ? 'Enter the ${LoginController.otpLength}-digit code sent to ${controller.maskedMobile.value}'
              : 'Enter the ${LoginController.otpLength}-digit code sent to your registered mobile number',
          style: const TextStyle(color: Colors.white70, fontSize: 13),
          textAlign: TextAlign.center,
        )),
        const SizedBox(height: 28),

        // OTP boxes with SMS autofill
        SizedBox(
          height: 58,
          child: OtpBoxesInput(
            controller: controller.otpController,
            length: LoginController.otpLength,
            onChanged: (code) => controller.otpError.value = '',
            onCompleted: (code) => controller.verifyOtp(),
          ),
        ),

        Obx(() => controller.otpError.value.isNotEmpty
            ? Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            controller.otpError.value,
            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        )
            : const SizedBox(height: 12)),

        const SizedBox(height: 20),

        // Verify button
        Obx(() {
          final locked = controller.otpAttemptsLeft.value == 0;
          return SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (controller.isVerifyingOtp.value || locked) ? null : controller.verifyOtp,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.white.withOpacity(0.5),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: controller.isVerifyingOtp.value
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
              )
                  : const Text(
                'VERIFY & LOGIN',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 2),
              ),
            ),
          );
        }),

        const SizedBox(height: 18),

        // Resend
        Obx(() {
          final secs = controller.resendSecondsLeft.value;
          final disabled = secs > 0 || controller.isResendingOtp.value;
          return TextButton(
            onPressed: disabled ? null : controller.resendOtp,
            child: controller.isResendingOtp.value
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
                : Text(
              secs > 0
                  ? 'Resend code in 0:${secs.toString().padLeft(2, '0')}'
                  : "Didn't get a code? Resend",
              style: TextStyle(color: Colors.white.withOpacity(disabled ? 0.5 : 1)),
            ),
          );
        }),

        TextButton(
          onPressed: controller.backToCredentials,
          style: TextButton.styleFrom(overlayColor: Colors.white),
          child: const Text(
            'Use a different account',
            style: TextStyle(color: AppColors.surface),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}


class OtpBoxesInput extends StatefulWidget {
  final TextEditingController controller;
  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;
  final double boxWidth;
  final double boxHeight;
  final double spacing;

  const OtpBoxesInput({
    super.key,
    required this.controller,
    required this.length,
    this.onChanged,
    this.onCompleted,
    this.boxWidth = 52,
    this.boxHeight = 58,
    this.spacing = 10,
  });

  @override
  State<OtpBoxesInput> createState() => _OtpBoxesInputState();
}

class _OtpBoxesInputState extends State<OtpBoxesInput>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focusNode;
  late final AnimationController _caretBlink;

  // Re-entrancy guard: setting controller.selection below synchronously
  // re-fires the listener (TextEditingController notifies on ANY value
  // change, text or selection). Without this we'd either loop or
  // double-process the same logical change.
  bool _guardingSelection = false;

  // Tracked so we can tell a single keystroke (delta ±1) apart from a
  // paste/SMS-autofill (delta > 1 in one shot) inside the listener.
  late String _previousText;

  @override
  void initState() {
    super.initState();
    _previousText = widget.controller.text;
    _focusNode = FocusNode(debugLabel: 'otpHiddenField');
    _caretBlink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    widget.controller.addListener(_handleControllerChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _handleControllerChange() {
    // Ignore the re-entrant call caused by us setting selection below.
    if (_guardingSelection) return;

    final newText = widget.controller.text;
    final textChanged = newText != _previousText;

    if (textChanged) {
      final lengthDelta = newText.length - _previousText.length;
      _previousText = newText;

      // Only override the caret for a multi-char jump (paste / SMS
      // autofill dropping the whole code in at once) or a genuinely
      // invalid selection. A single typed digit or single backspace
      // already carries a correct caret position from Flutter/our own
      // tap handler — don't stomp on it, that was the original bug.
      if (lengthDelta.abs() > 1 || !widget.controller.selection.isValid) {
        _setSelectionSafely(TextSelection.collapsed(offset: newText.length));
      }

      widget.onChanged?.call(newText);
      if (newText.length == widget.length) {
        widget.onCompleted?.call(newText);
      }
    }

    setState(() {}); // repaint boxes (covers text changes AND caret moves)
  }

  void _setSelectionSafely(TextSelection selection) {
    _guardingSelection = true;
    widget.controller.selection = selection;
    _guardingSelection = false;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChange);
    _focusNode.dispose();
    _caretBlink.dispose();
    super.dispose();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        widget.controller.text.isEmpty) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Handles a tap on box [index]. [localDx] is the tap's x position
  /// within that box (0..boxWidth), used to decide whether the caret
  /// should land before or after a digit that's already there.
  void _handleBoxTap(int index, double localDx) {
    final code = widget.controller.text;
    final int targetOffset;

    if (index >= code.length) {
      // Tapped an empty box (or the box right past the last digit) —
      // the caret can't go further than the end of the entered text.
      targetOffset = code.length;
    } else {
      // Tapped a box that already holds a digit: land the caret on
      // whichever side of the digit was actually tapped, same as
      // clicking inside a normal text field.
      final tappedRightHalf = localDx > widget.boxWidth / 2;
      targetOffset = tappedRightHalf ? index + 1 : index;
    }

    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
    _setSelectionSafely(TextSelection.collapsed(offset: targetOffset));
    setState(() {}); // move the highlight/caret now — text didn't change,
    // so _handleControllerChange's textChanged branch
    // won't fire to do it for us.
  }

  void _handleFallbackTap() {
    // Tapped in a gap between boxes / outside all of them — just focus
    // and go to the append point.
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
    _setSelectionSafely(
      TextSelection.collapsed(offset: widget.controller.text.length),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final code = widget.controller.text;
    final cursorOffset = widget.controller.selection.isValid
        ? widget.controller.selection.baseOffset.clamp(0, code.length)
        : code.length;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleFallbackTap,
      child: SizedBox(
        height: widget.boxHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Hidden field FIRST (bottom of the stack) and wrapped in
            // IgnorePointer: it exists purely to own focus, the
            // keyboard, paste, and SMS autofill. It must never
            // intercept taps — Opacity alone does NOT stop hit-testing,
            // only IgnorePointer does. That was the actual root cause:
            // every tap was being swallowed by this field (with
            // enableInteractiveSelection:false disabling its own
            // tap-to-place-caret), so nothing you tapped ever moved
            // the cursor.
            IgnorePointer(
              child: Opacity(
                opacity: 0.0,
                child: Focus(
                  onKeyEvent: _handleKey,
                  child: SizedBox(
                    width: widget.boxWidth * widget.length,
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: widget.length,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      enableInteractiveSelection: false,
                      showCursor: false,
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Visible boxes ON TOP — each owns its own tap handler now.
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(widget.length, (i) {
                final filled = i < code.length;
                final isCursorHere = i == cursorOffset;
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (details) =>
                      _handleBoxTap(i, details.localPosition.dx),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: widget.boxWidth,
                    height: widget.boxHeight,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(filled ? 0.18 : 0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: filled || (isCursorHere && _focusNode.hasFocus)
                            ? Colors.white
                            : Colors.white.withOpacity(0.35),
                        width: isCursorHere && _focusNode.hasFocus ? 2 : 1.5,
                      ),
                    ),
                    child: filled
                        ? Text(
                      code[i],
                      style: const TextStyle(
                        fontSize: 22,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                        : (isCursorHere && _focusNode.hasFocus)
                        ? FadeTransition(
                      opacity: _caretBlink,
                      child: Container(
                        width: 2,
                        height: 24,
                        color: Colors.white,
                      ),
                    )
                        : const SizedBox.shrink(),
                  ),
                );
              }),
            ),
          ],
        ),
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
                  'Session expired \n Continue and enter otp to login',
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


