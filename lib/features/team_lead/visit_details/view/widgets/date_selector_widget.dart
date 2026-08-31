import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:lifenity_connect/constants/app_assets.dart';

import '../../provider/visit_providers.dart';

class DateSelectorWidget extends ConsumerWidget {
  const DateSelectorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Day Button
          _buildNavigationButton(
            context: context,
            ref: ref,
            icon: Icons.chevron_left,
            onTap: () => _navigateDate(ref, -1),
          ),

          // Date Display with Calendar Icon
          Flexible(
            child: GestureDetector(
              onTap: () => _selectDate(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(AppAssets.calendarIcon, width: 20, height: 20, colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn)),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd MMM yyyy').format(selectedDate),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Next Day Button
          _buildNavigationButton(
            context: context,
            ref: ref,
            icon: Icons.chevron_right,
            onTap: () => _navigateDate(ref, 1),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton({
    required BuildContext context,
    required WidgetRef ref,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  void _navigateDate(WidgetRef ref, int days) {
    final currentDate = ref.read(selectedDateProvider);
    final newDate = currentDate.add(Duration(days: days));

    // Prevent selecting future dates
    if (days > 0 && newDate.isAfter(DateTime.now())) {
      return;
    }

    ref.read(selectedDateProvider.notifier).state = newDate;
  }

  Future<void> _selectDate(BuildContext context, WidgetRef ref) async {
    final selectedDate = ref.read(selectedDateProvider);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      ref.read(selectedDateProvider.notifier).state = pickedDate;
    }
  }
}