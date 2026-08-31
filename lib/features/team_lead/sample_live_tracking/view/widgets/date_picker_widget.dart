import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../theme/app_colors.dart';

class DateRangePickerSheet extends StatefulWidget {
  final DateTime initialFrom;
  final DateTime initialTo;
  final ValueChanged<DateTimeRange> onApply;

  const DateRangePickerSheet({
    super.key,
    required this.initialFrom,
    required this.initialTo,
    required this.onApply,
  });

  static Future<void> show(
      BuildContext context, {
        required DateTime from,
        required DateTime to,
        required ValueChanged<DateTimeRange> onApply,
      }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DateRangePickerSheet(
        initialFrom: from,
        initialTo: to,
        onApply: onApply,
      ),
    );
  }

  @override
  State<DateRangePickerSheet> createState() => _DateRangePickerSheetState();
}

class _DateRangePickerSheetState extends State<DateRangePickerSheet> {
  late DateTime _viewMonth;   // which month is shown
  late DateTime? _start;
  late DateTime? _end;
  bool _pickingEnd = false;   // false = next tap is start, true = next tap is end

  final _today    = _midnight(DateTime.now());
  late  DateTime  _minDate;

  static DateTime _midnight(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  // ── Quick presets ──────────────────────────────────────────────────────────
  static const List<(String, int)> _presets = [
    ('Today', 0),
    ('Last 7d', 7),
    ('Last 14d', 14),
    ('Last 30d', 30),
  ];
  int? _activePreset;

  @override
  void initState() {
    super.initState();
    _minDate   = _today.subtract(const Duration(days: 30));
    _start     = _midnight(widget.initialFrom);
    _end       = _midnight(widget.initialTo);
    _viewMonth = DateTime(_end!.year, _end!.month);
    _detectPreset();
  }

  void _detectPreset() {
    if (_start == null || _end == null) return;
    final diff = _today.difference(_start!).inDays;
    if (_end == _today) {
      for (final (_, days) in _presets) {
        if (diff == days) { _activePreset = days; return; }
      }
    }
    _activePreset = null;
  }

  void _applyPreset(int days) {
    setState(() {
      _activePreset = days;
      _end = _today;

      _start = days == 0
          ? _today
          : _today.subtract(Duration(days: days));

      // Fixed: Safe comparison for nullable DateTime
      if (_start != null && _minDate != null && _start!.isBefore(_minDate!)) {
        _start = _minDate;
      }

      _pickingEnd = false;
    });
  }

  void _onDayTap(DateTime day) {
    setState(() {
      _activePreset = null;
      if (!_pickingEnd) {
        _start = day; _end = null; _pickingEnd = true;
      } else {
        if (day.isBefore(_start!)) {
          _end = _start; _start = day;
        } else {
          _end = day;
        }
        _pickingEnd = false;
        _detectPreset();
      }
    });
  }

  void _prevMonth() {
    final prev = DateTime(_viewMonth.year, _viewMonth.month - 1);
    if (!prev.isBefore(DateTime(_minDate.year, _minDate.month))) {
      setState(() => _viewMonth = prev);
    }
  }

  void _nextMonth() {
    final next = DateTime(_viewMonth.year, _viewMonth.month + 1);
    if (!next.isAfter(DateTime(_today.year, _today.month))) {
      setState(() => _viewMonth = next);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
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
            _quickChips(theme),
            _rangeLabel(theme),
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
        width: 36, height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
  );

  Widget _header(ThemeData t) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
    child: Row(
      children: [
        Text('Select date range', style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
        const Spacer(),
        Text('Last 30 days only',
            style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurface.withOpacity(0.4))),
      ],
    ),
  );

  Widget _quickChips(ThemeData t) => SizedBox(
    height: 42,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      children: _presets.map<Widget>(((String, int) preset) {
        final label = preset.$1;  // record field access
        final days  = preset.$2;
        final active = _activePreset == days;

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => _applyPreset(days),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? AppColors.primary : AppColors.border,
                  width: 0.5,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: active
                      ? Colors.white
                      : t.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );

  Widget _rangeLabel(ThemeData t) {
    final fmt = DateFormat('MMM d, yyyy');
    String text;
    if (_start != null && _end != null) {
      text = '${fmt.format(_start!)}  →  ${fmt.format(_end!)}';
    } else if (_start != null) {
      text = '${fmt.format(_start!)}  →  pick end date';
    } else {
      text = 'Tap a date to begin';
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      color: AppColors.blueLight,
      child: Row(
        children: [
          Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.blueText),
          const SizedBox(width: 8),
          Text(text,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.blueText),
          ),
        ],
      ),
    );
  }

  Widget _calendarNav(ThemeData t) {
    final label = DateFormat('MMMM yyyy').format(_viewMonth);
    final canPrev = DateTime(_viewMonth.year, _viewMonth.month - 1)
        .compareTo(DateTime(_minDate.year, _minDate.month)) >= 0;
    final canNext = DateTime(_viewMonth.year, _viewMonth.month + 1)
        .compareTo(DateTime(_today.year, _today.month)) <= 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Row(
        children: [
          _navBtn(Icons.chevron_left_rounded, canPrev ? _prevMonth : null),
          Expanded(
            child: Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          _navBtn(Icons.chevron_right_rounded, canNext ? _nextMonth : null),
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 0.5),
        borderRadius: BorderRadius.circular(8),
        color: onTap != null ? AppColors.bgCard : AppColors.bgCardAlt,
      ),
      child: Icon(icon, size: 18,
          color: onTap != null ? AppColors.textSecondary : AppColors.textTertiary),
    ),
  );

  Widget _weekdayRow(ThemeData t) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: Row(
      children: ['Su','Mo','Tu','We','Th','Fr','Sa'].map((d) =>
          Expanded(
            child: Center(
              child: Text(d,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                    color: t.colorScheme.onSurface.withOpacity(0.35)),
              ),
            ),
          ),
      ).toList(),
    ),
  );

  Widget _daysGrid(ThemeData t) {
    final firstWeekday = DateTime(_viewMonth.year, _viewMonth.month, 1).weekday % 7;
    final daysInMonth  = DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;

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
          return _DayCell(
            day:      day,
            today:    _today,
            minDate:  _minDate,
            maxDate:  _today,
            start:    _start,
            end:      _end,
            onTap:    _onDayTap,
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
            child: const Text('Cancel', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: (_start != null && _end != null)
                ? () {
              widget.onApply(DateTimeRange(start: _start!, end: _end!));
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
            child: const Text('Apply range', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    ),
  );
}

// ── Day cell ───────────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  final DateTime day, today, minDate, maxDate;
  final DateTime? start, end;
  final ValueChanged<DateTime> onTap;

  const _DayCell({
    required this.day, required this.today, required this.minDate,
    required this.maxDate, required this.start, required this.end,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled   = day.isAfter(maxDate) || day.isBefore(minDate);
    final isToday    = day == today;
    final isStart    = start != null && day == start;
    final isEnd      = end   != null && day == end;
    final isInRange  = start != null && end != null &&
        day.isAfter(start!) && day.isBefore(end!);

    Color? bg;
    Color textColor = disabled
        ? AppColors.textTertiary.withOpacity(0.4)
        : AppColors.textPrimary;
    BorderRadius radius = BorderRadius.circular(8);

    if (isStart || isEnd) {
      bg = AppColors.primary;
      textColor = Colors.white;
      radius = BorderRadius.horizontal(
        left:  isStart ? const Radius.circular(8) : Radius.zero,
        right: isEnd   ? const Radius.circular(8) : Radius.zero,
      );
    } else if (isInRange) {
      bg = AppColors.blueLight;
      textColor = AppColors.blueText;
      radius = BorderRadius.zero;
    }

    return GestureDetector(
      onTap: disabled ? null : () => onTap(day),
      child: Container(
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(color: bg, borderRadius: radius),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text('${day.day}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: (isStart || isEnd) ? FontWeight.w600 : FontWeight.w400,
                color: textColor,
              ),
            ),
            if (isToday && !isStart && !isEnd && !isInRange)
              Positioned(
                bottom: 5,
                child: Container(
                  width: 4, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}