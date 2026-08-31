import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_theme.dart';

class StatusSummaryCard extends StatelessWidget {
  final String bgAsset;
  final int count;
  final String label;
  final Color borderColor;
  final VoidCallback? onTap;

  const StatusSummaryCard({
    super.key,
    required this.bgAsset,
    required this.count,
    required this.label,
    required this.borderColor,
    this.onTap,
  });

  void _handleTap() {
    if (onTap != null) {
      HapticFeedback.mediumImpact();
      onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap != null ? _handleTap : null,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.5),
          image: DecorationImage(
            image: AssetImage(bgAsset),
            fit: BoxFit.fill,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: AppTextStyles.statLabel.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
