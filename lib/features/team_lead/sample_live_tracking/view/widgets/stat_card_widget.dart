import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_theme.dart';


class StatCardWidget extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String subLabel;
  final VoidCallback? onTap;

  const StatCardWidget({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subLabel,
    this.onTap,
  });
  void _handleTap() {
    if (onTap != null) {
      // Haptic feedback
      HapticFeedback.mediumImpact();
      onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null ? _handleTap : null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: AppTextStyles.statLabel),
                  const SizedBox(height: 2),
                  Text(value, style: AppTextStyles.statNumber),
                  const SizedBox(height: 1),
                  Text(subLabel, style: AppTextStyles.statSub),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
