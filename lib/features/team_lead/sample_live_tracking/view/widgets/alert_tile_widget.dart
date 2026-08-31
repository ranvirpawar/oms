import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_theme.dart';


class AlertTileWidget extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String message;
  final String subMessage;
  final String timeAgo;
  final VoidCallback? onTap;

  const AlertTileWidget({
    super.key,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.message,
    required this.subMessage,
    required this.timeAgo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subMessage, style: AppTextStyles.bodySecondary),
                ],
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                /*Text(timeAgo, style: AppTextStyles.caption),
                const SizedBox(height: 4),*/
                const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textTertiary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
