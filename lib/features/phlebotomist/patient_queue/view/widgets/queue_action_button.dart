import 'package:flutter/material.dart';

import '../../../../../theme/app_colors.dart';

enum QueueActionStyle { filled, outlined, gradient }

/// Action button used in the patient card footer (Reject / Reschedule /
/// Accept & Start / Start Route).
///
/// Handles its own busy state (spinner + disabled taps) so the card never
/// needs to duplicate that logic per-button — the controller just flips
/// [isLoading] via `Obx` and this widget takes care of the rest, which
/// also guards against rapid double taps firing multiple requests.
class QueueActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final Gradient? gradient;
  final QueueActionStyle style;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback? onPressed;

  const QueueActionButton({
    super.key,
    required this.label,
    this.icon,
    required this.color,
    this.gradient,
    this.style = QueueActionStyle.filled,
    this.isLoading = false,
    this.isDisabled = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final effectivelyDisabled = isDisabled || isLoading;
    final content = isLoading
        ? SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                style == QueueActionStyle.outlined ? color : Colors.white,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
             /* if (icon != null) ...[
                Icon(icon,
                    size: 14,
                    color: style == QueueActionStyle.outlined
                        ? color
                        : Colors.white),
                const SizedBox(width: 6),
              ],*/
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: style == QueueActionStyle.outlined
                        ? color
                        : Colors.white,
                  ),
                ),
              ),
            ],
          );

    final child = SizedBox(
      height: 40,
      child: Center(child: content),
    );

    switch (style) {
      case QueueActionStyle.outlined:
        return SizedBox(
          height: 40,
          child: OutlinedButton(
            onPressed: effectivelyDisabled ? null : onPressed,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                  color: effectivelyDisabled
                      ? AppColors.outline
                      : color.withOpacity(0.5)),
              foregroundColor: color,
              disabledForegroundColor: AppColors.textDisabled,
              padding: const EdgeInsets.symmetric(horizontal: 0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: child,
          ),
        );
      case QueueActionStyle.gradient:
        return Opacity(
          opacity: effectivelyDisabled ? 0.55 : 1,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: effectivelyDisabled ? null : onPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: child,
                ),
              ),
            ),
          ),
        );
      case QueueActionStyle.filled:
        return SizedBox(
          height: 40,
          child: ElevatedButton(
            onPressed: effectivelyDisabled ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              disabledBackgroundColor: AppColors.outline,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: child,
          ),
        );
    }
  }
}
