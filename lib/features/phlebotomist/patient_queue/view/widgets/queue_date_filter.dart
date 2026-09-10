import 'package:flutter/material.dart';

/// Date horizon for the queue. Deliberately forward-looking (no "last N
/// days" presets) — this screen is about what a phlebotomist needs to act
/// on *next*, not a historical range.
enum QueueDateFilter { today, thisWeek, future }

extension QueueDateFilterX on QueueDateFilter {
  String get label => switch (this) {
        QueueDateFilter.today => 'Today',
        QueueDateFilter.thisWeek => 'This week',
        QueueDateFilter.future => 'Upcoming',
      };

  IconData get icon => switch (this) {
        QueueDateFilter.today => Icons.today_rounded,
        QueueDateFilter.thisWeek => Icons.view_week_rounded,
        QueueDateFilter.future => Icons.event_available_rounded,
      };
}
