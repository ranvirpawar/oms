import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_colors.dart';

/// A centralized service for showing in-app messages (snackbars, dialogs) using GetX.
class SnackBarService {
  // Make this a singleton
  SnackBarService._();
  static final SnackBarService to = SnackBarService._();

  /// Show a simple snackbar at bottom
  void showSnack({
    required String title,
    required String message,
    Color? backgroundColor,
    Color? titleColor,
    Color? messageColor,
    SnackPosition position = SnackPosition.BOTTOM,
    Duration duration = const Duration(seconds: 1),
    bool isError = false,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: position,
      backgroundColor:
          backgroundColor ?? (isError ? Colors.redAccent : Colors.green),
      colorText: messageColor ?? Colors.white,
      titleText: titleColor != null
          ? Text(title,
              style: TextStyle(color: titleColor, fontWeight: FontWeight.bold))
          : null,
      margin: const EdgeInsets.all(12),
      borderRadius: 8,
      duration: duration,
    );
  }

  /// Show a snackbar with only a message (no title)
  void showMessage({
    required String message,
    Color? backgroundColor,
    Color? messageColor,
    SnackPosition position = SnackPosition.BOTTOM,
    Duration duration = const Duration(seconds: 1),
  }) {
    Get.rawSnackbar(
      messageText: Text(
        message,
        style: TextStyle(color: messageColor ?? Colors.white),
      ),
      backgroundColor: backgroundColor ?? AppColors.tertiary900,
      snackPosition: position,
      duration: duration,
      borderRadius: 8,
      margin: const EdgeInsets.all(12),
      animationDuration: Duration.zero,
      forwardAnimationCurve: Curves.linear,
      reverseAnimationCurve: Curves.linear,
    );
  }
  void quickNotify({
    required String message,
    Color? backgroundColor,
    Color? messageColor,
    SnackPosition position = SnackPosition.BOTTOM,
    Duration duration = const Duration(seconds: 1),
  }) {
    Get.rawSnackbar(
      messageText: Text(
        message,
        style: TextStyle(
          color: messageColor ?? Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: backgroundColor ?? AppColors.tertiary900,
      snackPosition: position,
      duration: duration,
      borderRadius: 8,
      margin: const EdgeInsets.all(12),
      snackStyle: SnackStyle.FLOATING,

      // 👇 This kills the slide/animation
      animationDuration: Duration.zero,
      forwardAnimationCurve: Curves.linear,
      reverseAnimationCurve: Curves.linear,
    );
  }

  /// Show a confirmation dialog
  Future<bool?> showConfirmation({
    required String title,
    required String middleText,
    String confirmText = 'Yes',
    String cancelText = 'No',
  }) {
    return Get.defaultDialog<bool>(
      title: title,
      middleText: middleText,
      textConfirm: confirmText,
      textCancel: cancelText,
      confirmTextColor: Colors.white,
      onConfirm: () => Get.back(result: true),
      onCancel: () => Get.back(result: false),
    );
  }

  /// Show an info dialog
  void showInfoDialog({
    required String title,
    required String content,
    String buttonText = 'OK',
  }) {
    Get.defaultDialog(
      title: title,
      middleText: content,
      textConfirm: buttonText,
      confirmTextColor: Colors.white,
      onConfirm: () => Get.back(),
    );
  }

  void showMessageWithAction({
    required String message,
    required String actionLabel,
    required VoidCallback onAction,
    Color? backgroundColor,
    Color? messageColor,
    SnackPosition position = SnackPosition.BOTTOM,
    Duration duration = const Duration(seconds: 4),
  }) {
    Get.rawSnackbar(
      messageText: Text(
        message,
        style: TextStyle(color: messageColor ?? Colors.white),
      ),
      mainButton: TextButton(
        onPressed: onAction,
        child: Text(
          actionLabel,
          style: const TextStyle(color: Colors.yellow),
        ),
      ),
      backgroundColor: backgroundColor ?? AppColors.primary600,
      snackPosition: position,
      duration: duration,
      borderRadius: 8,
      margin: const EdgeInsets.all(12),
    );
  }
  void showQuickNotification({
    required String message,
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(milliseconds: 800),
  }) {
    // Use Get.overlayContext to avoid requiring BuildContext
    if (Get.overlayContext == null) return;

    final overlay = Overlay.of(Get.overlayContext!);
    late OverlayEntry overlayEntry;

    // Get screen size from Get.overlayContext
    final screenSize = MediaQuery.of(Get.overlayContext!).size;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(

        left: (screenSize.width -100) / 2, // Assuming ~160px width for pop-up
        bottom: 30,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            // width: 160, // Fixed width for consistent centering
            decoration: BoxDecoration(
              color: backgroundColor ?? Colors.grey[800]!.withOpacity(0.85),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor ?? Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );

    // Insert the overlay
    overlay.insert(overlayEntry);

    // Remove after duration
    Future.delayed(duration, () {
      overlayEntry.remove();
    });
  }

  /// Show a quick "Coming Soon" notification at screen center
  void showComingSoonNotification({
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(milliseconds: 800),
  }) {
    showQuickNotification(
      message: 'Coming Soon',
      backgroundColor: backgroundColor ?? Colors.grey[800]!.withOpacity(0.85),
      textColor: textColor ?? Colors.white,
      duration: duration,
    );
  }
}


