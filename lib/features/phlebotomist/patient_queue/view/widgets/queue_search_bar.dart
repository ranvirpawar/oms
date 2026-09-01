import 'package:flutter/material.dart';

import '../../../../../theme/app_colors.dart';

/// Search field for filtering the queue by patient name, order ID, or
/// test name. Kept visually lightweight (no elevation of its own) since
/// it sits directly under the summary bar which already carries weight.
class QueueSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool showClear;
  final VoidCallback onClear;

  const QueueSearchBar({
    super.key,
    required this.controller,
    required this.showClear,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search by name, ID, or test',
            hintStyle:
                const TextStyle(color: AppColors.textMuted, fontSize: 13.5),
            prefixIcon: const Icon(Icons.search_rounded,
                size: 20, color: AppColors.textQuaternary),
            suffixIcon: showClear
                ? IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: AppColors.textQuaternary),
                    onPressed: onClear,
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          ),
        ),
      ),
    );
  }
}
