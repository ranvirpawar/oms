// ── Facility Dropdown ─────────────────────────────────────────────────────────
import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';

class ConsumptionFacilityDropdown extends StatelessWidget {
  final String selected;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const ConsumptionFacilityDropdown({super.key,
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          dropdownColor: AppColors.primary,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white70,
            size: 18,
          ),
          items: options
              .map(
                (name) => DropdownMenuItem(
              value: name,
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          )
              .toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }
}