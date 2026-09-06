import 'package:flutter/material.dart';

import '../../../../../theme/app_colors.dart';

/// Empty state for the queue list.
///
/// Distinguishes between "nothing assigned at all" and "nothing matches
/// your current filter/search" — these mean very different things to the
/// phlebotomist and deserve different copy + recovery action.
class QueueEmptyState extends StatelessWidget {
  final bool isFiltered;
  final VoidCallback? onClearFilter;

  const QueueEmptyState({
    super.key,
    this.isFiltered = false,
    this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    final title =
        isFiltered ? 'No matching patients' : 'No patients assigned yet';
    final subtitle = isFiltered
        ? 'Try a different filter or clear your search to see the full queue.'
        : 'New assignments for today will show up here automatically.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.primary50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFiltered
                    ? Icons.search_off_rounded
                    : Icons.checklist_rtl_rounded,
                size: 40,
                color: AppColors.primary400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textTertiary,
                height: 1.4,
              ),
            ),
            if (isFiltered && onClearFilter != null) ...[
              const SizedBox(height: 18),
              TextButton.icon(
                onPressed: onClearFilter,
                icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
                label: const Text('Clear filter'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
