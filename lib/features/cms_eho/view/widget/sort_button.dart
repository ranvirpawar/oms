import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../provider/consumption_providers.dart';

class SortButton extends StatelessWidget {
  final SortOption selected;
  final ValueChanged<SortOption> onSelected;

  const SortButton({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortOption>(
      onSelected: onSelected,
      color: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 40),
      itemBuilder: (_) => [
        _menuItem(
          SortOption.facilityName,
          'Facility Name',
          Icons.sort_by_alpha_rounded,
        ),
        _menuItem(
          SortOption.highestCompletion,
          'Highest Consumption %',
          Icons.trending_up_rounded,
        ),
        _menuItem(
          SortOption.lowestCompletion,
          'Lowest Consumption %',
          Icons.trending_down_rounded,
        ),
        // _menuItem(
        //   SortOption.highestTarget,
        //   'Highest Target',
        //   Icons.flag_rounded,
        // ),
      ],
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
      ),
    );
  }

  PopupMenuItem<SortOption> _menuItem(
      SortOption value,
      String label,
      IconData icon,
      ) {
    final isSelected = value == selected;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected ? Colors.white : Colors.white70,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isSelected ? Colors.white : Colors.white,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w400,

            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            const Icon(
              Icons.check_rounded,
              size: 14,
              color: Colors.white,
            ),
          ],
        ],
      ),
    );
  }
}