import 'package:flutter/material.dart';


enum QueueDateFilter { today, thisWeek, future, past, custom }

extension QueueDateFilterX on QueueDateFilter {
  String get label => switch (this) {
    QueueDateFilter.today => 'Today',
    QueueDateFilter.thisWeek => 'This Week',
    QueueDateFilter.future => 'Upcoming',
    QueueDateFilter.past => 'Past Orders',
    QueueDateFilter.custom => 'Pick Date',
  };

  IconData get icon => switch (this) {
    QueueDateFilter.today => Icons.today_rounded,
    QueueDateFilter.thisWeek => Icons.view_week_rounded,
    QueueDateFilter.future => Icons.event_available_rounded,
    QueueDateFilter.past => Icons.history_rounded,
    QueueDateFilter.custom => Icons.calendar_month_rounded,
  };

  /// The four selectable presets shown in the popover, in display order.
  /// `custom` isn't in here — it gets its own row + divider since picking
  /// it opens the calendar instead of applying immediately.
  static const presets = [
    QueueDateFilter.today,
    QueueDateFilter.thisWeek,
    QueueDateFilter.future,
    QueueDateFilter.past,
  ];
}