import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../../theme/app_colors.dart';


class QueueCalendarSheet extends StatefulWidget {
  final Set<DateTime> orderDates; // normalized to midnight
  final DateTime? initialSelected;
  final ValueChanged<DateTime> onSelect;

  const QueueCalendarSheet({
    super.key,
    required this.orderDates,
    required this.onSelect,
    this.initialSelected,
  });

  static Future<void> show(
      BuildContext context, {
        required Set<DateTime> orderDates,
        DateTime? initialSelected,
        required ValueChanged<DateTime> onSelect,
      }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QueueCalendarSheet(
        orderDates: orderDates,
        initialSelected: initialSelected,
        onSelect: onSelect,
      ),
    );
  }

  @override
  State<QueueCalendarSheet> createState() => _QueueCalendarSheetState();
}

class _QueueCalendarSheetState extends State<QueueCalendarSheet> {
  late DateTime _viewMonth;
  DateTime? _selected;

  static DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    _selected =
    widget.initialSelected != null ? _midnight(widget.initialSelected!) : null;
    final anchor = _selected ?? _midnight(DateTime.now());
    _viewMonth = DateTime(anchor.year, anchor.month);
  }

  bool _hasOrder(DateTime day) => widget.orderDates.contains(_midnight(day));

  void _prevMonth() =>
      setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1));

  void _nextMonth() =>
      setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1));

  void _pick(DateTime day) {
    HapticFeedback.selectionClick();
    setState(() => _selected = day);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _handle(),
            _header(theme),
            _calendarNav(theme),
            _weekdayRow(theme),
            _daysGrid(theme),
            _footer(theme),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _handle() => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 4),
    child: Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
  );

  Widget _header(ThemeData t) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 4, 18, 10),
    child: Row(
      children: [
        Text('Jump to a date',
            style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const Spacer(),
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(right: 5),
              decoration:
              BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            ),
            Text('Has orders',
                style: t.textTheme.bodySmall
                    ?.copyWith(color: t.colorScheme.onSurface.withOpacity(0.45))),
          ],
        ),
      ],
    ),
  );

  Widget _calendarNav(ThemeData t) {
    final label = DateFormat('MMMM yyyy').format(_viewMonth);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      child: Row(
        children: [
          _navBtn(Icons.chevron_left_rounded, _prevMonth),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          _navBtn(Icons.chevron_right_rounded, _nextMonth),
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 0.5),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.bgCard,
      ),
      child: Icon(icon, size: 18, color: AppColors.textSecondary),
    ),
  );

  Widget _weekdayRow(ThemeData t) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: Row(
      children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
          .map((d) => Expanded(
        child: Center(
          child: Text(
            d,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: t.colorScheme.onSurface.withOpacity(0.35),
            ),
          ),
        ),
      ))
          .toList(),
    ),
  );

  Widget _daysGrid(ThemeData t) {
    final firstWeekday = DateTime(_viewMonth.year, _viewMonth.month, 1).weekday % 7;
    final daysInMonth = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final today = _midnight(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          childAspectRatio: 1.0,
        ),
        itemCount: firstWeekday + daysInMonth,
        itemBuilder: (_, i) {
          if (i < firstWeekday) return const SizedBox();
          final day = DateTime(_viewMonth.year, _viewMonth.month, i - firstWeekday + 1);
          return _CalendarDayCell(
            day: day,
            today: today,
            hasOrder: _hasOrder(day),
            selected: _selected != null && day == _selected,
            onTap: () => _pick(day),
          );
        },
      ),
    );
  }

  Widget _footer(ThemeData t) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
    child: Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.border, width: 0.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            child: const Text('Cancel',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _selected != null
                ? () {
              widget.onSelect(_selected!);
              Navigator.pop(context);
            }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 13),
              elevation: 0,
            ),
            child: const Text('Show orders',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    ),
  );
}

class _CalendarDayCell extends StatelessWidget {
  final DateTime day, today;
  final bool hasOrder, selected;
  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.day,
    required this.today,
    required this.hasOrder,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Gate: a day with no order simply isn't tappable — no error state
    // needed, the muted look communicates "nothing here" up front.
    final disabled = !hasOrder;
    final isToday = day == today;

    Color? bg;
    Color textColor =
    disabled ? AppColors.textTertiary.withOpacity(0.35) : AppColors.textPrimary;

    if (selected) {
      bg = AppColors.primary;
      textColor = Colors.white;
    }

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: isToday && !selected
              ? Border.all(color: AppColors.primary.withOpacity(0.5), width: 1)
              : null,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: textColor,
              ),
            ),
            if (hasOrder && !selected)
              Positioned(
                bottom: 4,
                child: Container(
                  width: 4,
                  height: 4,
                  decoration:
                  BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}