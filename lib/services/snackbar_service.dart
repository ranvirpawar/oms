import 'package:flutter/material.dart';
import 'package:get/get.dart' hide SnackPosition;

import '../utils/ui_designs/liquid_snackbar.dart';

/// Centralized in-app messaging facade.
///
/// Every method renders through the **Liquid Glass** snackbar system
/// ([LiquidSnack]) — a modern glass card/pill with a per-variant icon and
/// fixed WCAG-compliant contrast — instead of the legacy GetX snackbar UI.
/// Call sites keep the same API; only the visual layer changed.
class SnackBarService {
  // Make this a singleton
  SnackBarService._();
  static final SnackBarService to = SnackBarService._();

  /// Show a simple glass snackbar at bottom.
  ///
  /// `isError` picks the red error card, otherwise the green success card.
  void showSnack({
    required String title,
    required String message,
    Color? backgroundColor,
    Color? titleColor,
    Color? messageColor,
    SnackPosition position = SnackPosition.bottom,
    Duration duration = const Duration(seconds: 1),
    bool isError = false,
  }) {
    if (isError) {
      LiquidSnack.error(message, title: title);
    } else {
      LiquidSnack.success(message, title: title);
    }
  }

  /// Minimal glass pill for a short neutral message.
  ///
  /// Pass [variant] when the message is clearly a success/warning/error so the
  /// card gets the matching icon + color.
  void showMessage({
    required String message,
    Color? backgroundColor,
    Color? messageColor,
    SnackPosition position = SnackPosition.bottom,
    Duration duration = const Duration(seconds: 1),
    SnackVariant variant = SnackVariant.neutral,
  }) {
    if (variant == SnackVariant.neutral) {
      LiquidSnack.quick(message, position: position, duration: duration);
    } else {
      LiquidSnack.show(
        message: message,
        variant: variant,
        position: position,
        duration: duration,
      );
    }
  }
  void quickNotify({
    required String message,
    Color? backgroundColor,
    Color? messageColor,
    SnackPosition position = SnackPosition.bottom,
    Duration duration = const Duration(seconds: 1),
  }) {
    LiquidSnack.quick(message, position: position, duration: duration);
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
    SnackPosition position = SnackPosition.bottom,
    Duration duration = const Duration(seconds: 4),
  }) {
    LiquidSnack.withAction(
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }
  void showQuickNotification({
    required String message,
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(milliseconds: 800),
  }) {
    LiquidSnack.quick(message, duration: duration);
  }

  /// Show a quick "Coming Soon" notification
  void showComingSoonNotification({
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(milliseconds: 800),
  }) {
    LiquidSnack.info('Coming Soon');
  }
}


