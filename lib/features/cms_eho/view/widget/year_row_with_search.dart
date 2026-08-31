import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_colors.dart';
import '../../model/facility_detail_model.dart';

class YearRowWithSearch extends StatelessWidget {
  final AsyncValue<List<ProjectFinancialYear>> yearsAsync;
  final int selectedYear;
  final bool searchOpen;
  final TextEditingController searchCtrl;
  final FocusNode searchFocus;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onToggleSearch;
  final ValueChanged<int> onYearSelected; // ✅ add this

  const YearRowWithSearch({
    super.key,
    required this.yearsAsync,
    required this.selectedYear,
    required this.searchOpen,
    required this.searchCtrl,
    required this.searchFocus,
    required this.onSearchChanged,
    required this.onToggleSearch,
    required this.onYearSelected, // ✅
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: searchOpen
                ? _SearchField(
              key: const ValueKey('search'),
              controller: searchCtrl,
              focusNode: searchFocus,
              onChanged: onSearchChanged,
              onClose: onToggleSearch,
            )
                : _YearChipsRow(
              key: const ValueKey('chips'),
              yearsAsync: yearsAsync,
              selectedYear: selectedYear,
              onYearSelected: onYearSelected, // ✅
            ),
          ),
        ),
        if (!searchOpen) ...[
          const SizedBox(width: 8),
          _SearchToggleButton(onTap: onToggleSearch),
        ],
      ],
    );
  }
}

// ── Year chips (extracted so AnimatedSwitcher can key it) ─────────────────────
class _YearChipsRow extends StatelessWidget {
  final AsyncValue<List<ProjectFinancialYear>> yearsAsync;
  final int selectedYear;
  final ValueChanged<int> onYearSelected; // ✅ add this

  const _YearChipsRow({
    super.key,
    required this.yearsAsync,
    required this.selectedYear,
    required this.onYearSelected, // ✅
  });

  @override
  Widget build(BuildContext context) {
    return yearsAsync.when(
      loading: () => Container(
        height: 28,
        width: 140,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      error: (_, __) => _YearChip(
        label: 'Current Year',
        isSelected: true,
        onTap: () {},
      ),
      data: (years) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: years
              .map(
                (y) => _YearChip(
              label: y.yearDescription,
              isSelected: y.yearId == selectedYear,
              onTap: () => onYearSelected(y.yearId), // ✅
            ),
          )
              .toList(),
        ),
      ),
    );
  }
}

// ── Search toggle button ───────────────────────────────────────────────────────
class _SearchToggleButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchToggleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: const Icon(Icons.search_rounded, color: Colors.white, size: 16),
      ),
    );
  }
}

// ── Inline search field ────────────────────────────────────────────────────────
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  const _SearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        // color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          const Icon(Icons.search_rounded, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child:TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,

              ),
              decoration: const InputDecoration(
                hintText: 'Search facilities, wards…',
                hintStyle: TextStyle(color: Colors.white54, fontSize: 13),

                // Explicitly remove borders for all states to override any Theme settings
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,

                // isDense helps the TextField center properly within your 40px fixed-height Container
                isDense: true,
                contentPadding: EdgeInsets.zero,
                fillColor: Colors.transparent,
              ),
              cursorColor: Colors.white,
              textAlignVertical: TextAlignVertical.center,
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.close_rounded, color: Colors.white70, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Year Chip
// ─────────────────────────────────────────────────────────────────────────────
class _YearChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _YearChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.25),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}