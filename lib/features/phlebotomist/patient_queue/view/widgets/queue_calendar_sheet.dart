import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../../theme/app_colors.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../../theme/app_colors.dart';

class QueueCalendarSheet extends StatefulWidget {
  final DateTimeRange? initialRange;
  final ValueChanged<DateTimeRange> onSelect;

  const QueueCalendarSheet({
    super.key,
    required this.onSelect,
    this.initialRange,
  });

  static Future<void> show(
      BuildContext context, {
        DateTimeRange? initialRange,
        required ValueChanged<DateTimeRange> onSelect,
      }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QueueCalendarSheet(
        initialRange: initialRange,
        onSelect: onSelect,
      ),
    );
  }

  @override
  State<QueueCalendarSheet> createState() => _QueueCalendarSheetState();
}

class _QueueCalendarSheetState extends State<QueueCalendarSheet> {
  late DateTime _viewMonth;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  static DateTime _midnight(DateTime d) => DateTime(d.year, d.month, d.day);
  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void initState() {
    super.initState();
    if (widget.initialRange != null) {
      _rangeStart = _midnight(widget.initialRange!.start);
      _rangeEnd = _midnight(widget.initialRange!.end);
    }
    final anchor = _rangeStart ?? _midnight(DateTime.now());
    _viewMonth = DateTime(anchor.year, anchor.month);
  }

  void _prevMonth() =>
      setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1));

  void _nextMonth() =>
      setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1));

  // Tap logic: first tap starts a fresh range (start == end == tapped day).
  // Second tap extends it — before the start, it becomes the new start;
  // after (or on) the start, it becomes the end. A third tap starts over.
  void _pick(DateTime day) {
    HapticFeedback.selectionClick();
    setState(() {
      final start = _rangeStart;
      final end = _rangeEnd;
      final hasCompleteRange = start != null && end != null && !_sameDay(start, end);

      if (start == null || hasCompleteRange) {
        _rangeStart = day;
        _rangeEnd = day;
      } else if (day.isBefore(start)) {
        _rangeStart = day;
        _rangeEnd = start;
      } else {
        _rangeEnd = day;
      }
    });
  }

  bool get _hasRange =>
      _rangeStart != null && _rangeEnd != null && !_sameDay(_rangeStart!, _rangeEnd!);

  String get _rangeLabel {
    if (_rangeStart == null) return 'Select a start date';
    if (!_hasRange) return '${DateFormat('MMM d').format(_rangeStart!)} · pick an end date';
    final sameMonth = _rangeStart!.month == _rangeEnd!.month &&
        _rangeStart!.year == _rangeEnd!.year;
    final startLabel = DateFormat(sameMonth ? 'MMM d' : 'MMM d, yyyy').format(_rangeStart!);
    final endLabel = DateFormat('MMM d, yyyy').format(_rangeEnd!);
    return '$startLabel – $endLabel';
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
        Expanded(
          child: Text('Select a date range',
              style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: _rangeStart != null
              ? GestureDetector(
            key: const ValueKey('clear'),
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _rangeStart = null;
                _rangeEnd = null;
              });
            },
            child: Text(
              'Clear',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          )
              : const SizedBox(key: ValueKey('empty')),
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
    onTap: () {
      HapticFeedback.lightImpact();
      onTap();
    },
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

          final isStart = _rangeStart != null && _sameDay(day, _rangeStart!);
          final isEnd = _rangeEnd != null && _sameDay(day, _rangeEnd!);
          final inRange = _rangeStart != null &&
              _rangeEnd != null &&
              day.isAfter(_rangeStart!) &&
              day.isBefore(_rangeEnd!);

          // Column position within its row, used to decide whether the
          // connecting tint should bleed into the neighbouring cell so the
          // range reads as one continuous pill rather than isolated dots.
          final col = (i) % 7;
          final isRowStart = col == 0;
          final isRowEnd = col == 6;

          return _CalendarDayCell(
            day: day,
            today: today,
            isStart: isStart,
            isEnd: isEnd,
            inRange: inRange,
            isRowStart: isRowStart,
            isRowEnd: isRowEnd,
            onTap: () => _pick(day),
          );
        },
      ),
    );
  }

  Widget _footer(ThemeData t) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, left: 2),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: Text(
              _rangeLabel,
              key: ValueKey(_rangeLabel),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ),
        Row(
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
                onPressed: _rangeStart != null
                    ? () {
                  HapticFeedback.mediumImpact();
                  widget.onSelect(DateTimeRange(
                    start: _rangeStart!,
                    end: _rangeEnd ?? _rangeStart!,
                  ));
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
                child: const Text('Show Orders',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _CalendarDayCell extends StatelessWidget {
  final DateTime day, today;
  final bool isStart, isEnd, inRange, isRowStart, isRowEnd;
  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.day,
    required this.today,
    required this.isStart,
    required this.isEnd,
    required this.inRange,
    required this.isRowStart,
    required this.isRowEnd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = day == today;
    final isEndpoint = isStart || isEnd;
    // A single-day range (start == end) should look like a plain filled
    // pill, not a connector with a highlighted band, so only treat it as
    // "connected" when start and end are genuinely different days.
    final isSingleDay = isStart && isEnd;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Continuous tint band linking start -> end across the row.
            if (inRange || (isEndpoint && !isSingleDay))
              Positioned.fill(
                child: Row(
                  children: [
                    if (!isRowStart && (inRange || isEnd))
                      Expanded(child: Container(color: AppColors.primary.withOpacity(0.12)))
                    else
                      const Expanded(child: SizedBox()),
                    if (!isRowEnd && (inRange || isStart))
                      Expanded(child: Container(color: AppColors.primary.withOpacity(0.12)))
                    else
                      const Expanded(child: SizedBox()),
                  ],
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
              decoration: BoxDecoration(
                color: isEndpoint
                    ? AppColors.primary
                    : inRange
                    ? AppColors.primary.withOpacity(0.12)
                    : null,
                borderRadius: BorderRadius.circular(isEndpoint ? 8 : 8),
                border: isToday && !isEndpoint
                    ? Border.all(color: AppColors.primary.withOpacity(0.5), width: 1)
                    : null,
              ),
              child: Center(
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isEndpoint ? FontWeight.w600 : FontWeight.w400,
                    color: isEndpoint ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
/*class QueueCalendarSheet extends StatefulWidget {
  final DateTime? initialSelected;
  final ValueChanged<DateTime> onSelect;

  const QueueCalendarSheet({
    super.key,
    required this.onSelect,
    this.initialSelected,
  });

  static Future<void> show(
      BuildContext context, {
        DateTime? initialSelected,
        required ValueChanged<DateTime> onSelect,
      }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QueueCalendarSheet(
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
  final bool selected;
  final VoidCallback onTap;

  const _CalendarDayCell({
    required this.day,
    required this.today,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Every day is selectable now — the queue no longer knows in advance
    // which days have orders, since data is fetched per date window
    // rather than loaded in full up front.
    final isToday = day == today;

    Color? bg;
    Color textColor = AppColors.textPrimary;

    if (selected) {
      bg = AppColors.primary;
      textColor = Colors.white;
    }

    return GestureDetector(
      onTap: onTap,
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
        child: Center(
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}*/
/*
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
}*/
