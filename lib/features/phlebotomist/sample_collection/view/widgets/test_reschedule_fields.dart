import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../../theme/app_colors.dart';
import '../../../patient_queue/model/patient_queue_model.dart';
import '../../model/sample_collection_models.dart';

/// Compact reason and confirmed appointment summary. Timing is drafted in a sheet.
class TestRescheduleFields extends StatefulWidget {
  const TestRescheduleFields({
    super.key,
    required this.reasonOptions,
    required this.onFetchSlots,
    required this.onChanged,
    this.initialInfo,
    this.requireSchedule = true,
    this.showReason = true,
    this.testName = 'This test',
  });
  final List<IncompleteReasonOption> reasonOptions;
  final Future<List<AvailableSlot>> Function(DateTime) onFetchSlots;
  final ValueChanged<TestIncompleteInfo> onChanged;
  final TestIncompleteInfo? initialInfo;
  final bool requireSchedule;
  final bool showReason;
  final String testName;

  @override
  State<TestRescheduleFields> createState() => _TestRescheduleFieldsState();
}

class _TestRescheduleFieldsState extends State<TestRescheduleFields> {
  IncompleteReasonOption? _reason;
  DateTime? _date;
  AvailableSlot? _slot;

  @override
  void initState() {
    super.initState();
    _reason = widget.initialInfo?.reason;
    _date = widget.initialInfo?.appointmentDate;
    final info = widget.initialInfo;
    if (info?.slotId != null) {
      _slot = AvailableSlot(slotId: info!.slotId!, timeSlot: info.slotLabel);
    }
  }

  @override
  void didUpdateWidget(covariant TestRescheduleFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.showReason ||
        oldWidget.initialInfo?.reason.reasonId !=
            widget.initialInfo?.reason.reasonId) {
      _reason = widget.initialInfo?.reason;
    }
  }

  void _emit() {
    if (_reason == null) return;
    widget.onChanged(
      TestIncompleteInfo(
        reason: _reason!,
        remarks: widget.initialInfo?.remarks ?? '',
        appointmentDate: _date,
        slotId: _slot?.slotId,
        slotLabel: _slot == null ? '' : _slotLabel(_slot!),
      ),
    );
  }

  Future<void> _pickReason() async {
    final reason = await showModalBottomSheet<IncompleteReasonOption>(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Reason for another visit',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final reason in widget.reasonOptions)
                    ListTile(
                      dense: true,
                      title: Text(
                        reason.reason,
                        style: const TextStyle(fontSize: 13),
                      ),
                      trailing: reason.reasonId == _reason?.reasonId
                          ? const Icon(
                              Icons.check_rounded,
                              color: AppColors.primary,
                            )
                          : null,
                      onTap: () => Navigator.of(context).pop(reason),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (reason == null || !mounted) return;
    HapticFeedback.selectionClick();
    setState(() => _reason = reason);
    _emit();
  }

  Future<void> _pickTiming() async {
    final timing = await showModalBottomSheet<_CollectionTiming>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CollectionTimingSheet(
        testName: widget.testName,
        onFetchSlots: widget.onFetchSlots,
        initialDate: _date,
        initialSlot: _slot,
      ),
    );
    if (timing == null || !mounted) return;
    setState(() {
      _date = timing.date;
      _slot = timing.slot;
    });
    _emit();
  }

  Widget _row({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    String? subtitle,
  }) => Material(
    color: AppColors.grayLight,
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 17, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (widget.showReason) ...[
        _row(
          icon: Icons.notes_rounded,
          label: _reason?.reason ?? 'Select reason',
          onTap: widget.reasonOptions.isEmpty ? null : _pickReason,
        ),
        if (widget.reasonOptions.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Reasons could not be loaded. Please reopen the checklist.',
              style: TextStyle(fontSize: 11, color: AppColors.error),
            ),
          ),
        const SizedBox(height: 6),
      ],
      _row(
        icon: Icons.event_available_rounded,
        label: _date != null && _slot != null
            ? '${DateFormat('dd MMM yyyy').format(_date!)} · ${_slotLabel(_slot!)}'
            : 'Choose collection time',
        subtitle: _date != null && _slot != null
            ? 'Agreed with the patient · Tap to change'
            : widget.requireSchedule
            ? 'Ask the patient when we should return'
            : 'Plan another visit, if needed',
        onTap: _pickTiming,
      ),
    ],
  );
}

/// Start time for API slots and persisted display labels, including legacy ranges.
/// Saved plans have a label but no InTime; never parse an empty value.
String formatCollectionStartTime(String value) {
  final text = value.trim();
  final match = RegExp(
    r'^(\d{1,2}):(\d{2})(?::\d{2})?\s*(AM|PM)?',
    caseSensitive: false,
  ).firstMatch(text);
  if (match == null) return text.isEmpty ? 'Selected time slot' : text;
  var hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  final period = match.group(3)?.toUpperCase();
  if (minute > 59 || hour > 23 || (period != null && (hour < 1 || hour > 12))) {
    return text;
  }
  if (period != null) hour = hour % 12 + (period == 'PM' ? 12 : 0);
  return DateFormat('h:mm a').format(DateTime(2000, 1, 1, hour, minute));
}

String _slotLabel(AvailableSlot slot) => formatCollectionStartTime(
  slot.inTime.trim().isNotEmpty ? slot.inTime : slot.timeSlot,
);

class _CollectionTiming {
  const _CollectionTiming(this.date, this.slot);
  final DateTime date;
  final AvailableSlot slot;
}

class _CollectionTimingSheet extends StatefulWidget {
  const _CollectionTimingSheet({
    required this.testName,
    required this.onFetchSlots,
    this.initialDate,
    this.initialSlot,
  });
  final String testName;
  final Future<List<AvailableSlot>> Function(DateTime) onFetchSlots;
  final DateTime? initialDate;
  final AvailableSlot? initialSlot;
  @override
  State<_CollectionTimingSheet> createState() => _CollectionTimingSheetState();
}

class _CollectionTimingSheetState extends State<_CollectionTimingSheet> {
  late final List<DateTime> _dates;
  late DateTime _date;
  AvailableSlot? _slot;
  List<AvailableSlot> _slots = [];
  bool _loading = false;
  String _error = '';
  int _request = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dates = List.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day + i),
    );
    _date = _dates.firstWhere(
      (date) => DateUtils.isSameDay(date, widget.initialDate),
      orElse: () => _dates.first,
    );
    _loadSlots(preserveSlot: DateUtils.isSameDay(_date, widget.initialDate));
  }

  Future<void> _loadSlots({bool preserveSlot = false}) async {
    final request = ++_request;
    final date = _date;
    setState(() {
      _loading = true;
      _error = '';
      _slot = null;
      _slots = [];
    });
    try {
      final slots = await widget.onFetchSlots(date);
      if (!mounted || request != _request) return;
      setState(() {
        _slots = slots;
        if (preserveSlot) {
          final matches = slots.where(
            (slot) => slot.slotId == widget.initialSlot?.slotId,
          );
          _slot = matches.isEmpty ? null : matches.first;
        }
      });
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(
        () => _error = 'We could not load the time slots. Please try again.',
      );
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => DraggableScrollableSheet(
    initialChildSize: 0.65,
    minChildSize: 0.45,
    maxChildSize: 0.92,
    expand: false,

    builder: (context, scrollController) => Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Plan collection',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.testName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ask the patient when we should return to collect this test, then choose a date and available time slot.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select date',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 70,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _dates.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final date = _dates[index];
                      final selected = DateUtils.isSameDay(date, _date);
                      return Semantics(
                        button: true,
                        selected: selected,
                        label: DateFormat('EEEE, d MMMM').format(date),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            key: ValueKey('collection-date-$index'),
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              if (selected) return;
                              HapticFeedback.selectionClick();
                              setState(() => _date = date);
                              _loadSlots();
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              width: 56,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: selected
                                    ? AppColors.accentGradient
                                    : null,
                                color: selected ? null : AppColors.grayLight,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? Colors.transparent
                                      : AppColors.border,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat(
                                      'EEE',
                                    ).format(date).toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: selected
                                          ? Colors.white70
                                          : AppColors.textTertiary,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('d').format(date),
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: selected
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMM').format(date),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: selected
                                          ? Colors.white70
                                          : AppColors.textTertiary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select time slot',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                if (_error.isNotEmpty) ...[
                  Text(
                    _error,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _loadSlots,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Try again'),
                    ),
                  ),
                ],
                if (!_loading && _error.isEmpty && _slots.isEmpty)
                  const Text(
                    'No slots available for this date. Please choose another date.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                if (!_loading && _slots.isNotEmpty)
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const int columns = 4;
                      const double spacing = 8;
                      final double itemWidth =
                          (constraints.maxWidth - spacing * (columns - 1)) /
                          columns;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          for (final slot in _slots)
                            SizedBox(
                              width: itemWidth,
                              child: Semantics(
                                button: true,
                                selected: _slot?.slotId == slot.slotId,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    key: ValueKey(
                                      'collection-slot-${slot.slotId}',
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      setState(() => _slot = slot);
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 10,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      constraints: const BoxConstraints(
                                        minHeight: 44,
                                      ),
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: _slot?.slotId == slot.slotId
                                            ? AppColors.accentGradient
                                            : null,
                                        color: _slot?.slotId == slot.slotId
                                            ? null
                                            : AppColors.bgCard,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _slot?.slotId == slot.slotId
                                              ? Colors.transparent
                                              : AppColors.border,
                                        ),
                                      ),
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          _slotLabel(slot),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: _slot?.slotId == slot.slotId
                                                ? Colors.white
                                                : AppColors.textPrimary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent700,
                    disabledBackgroundColor: AppColors.border,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: !_loading && _slot != null
                      ? () => Navigator.of(
                          context,
                        ).pop(_CollectionTiming(_date, _slot!))
                      : null,
                  child: const Text(
                    'Confirm collection time',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
