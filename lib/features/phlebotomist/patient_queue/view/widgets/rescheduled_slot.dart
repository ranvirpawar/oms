import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/view/widgets/visit_type_badge.dart';

import '../../../../../theme/app_colors.dart';
import '../../model/patient_queue_model.dart';

class RescheduleSheet extends StatefulWidget {
  final AssignedPatient patient;

  /// Loads the available time slots for a picked date — wired to the
  /// controller's `user/available-slots` call. Errors should propagate so
  /// the sheet can show an inline retry state.
  final Future<List<AvailableSlot>> Function(DateTime date) onFetchSlots;

  /// Loads the selectable reschedule reasons — wired to the controller's
  /// `GetRescheduleReasone` call. Never throws; an empty list keeps the
  /// confirm gate locked.
  final Future<List<RescheduleReason>> Function() onFetchReasons;

  /// Persists the reschedule. Returns `true` so the sheet can stay open
  /// (showing the inline state) when the backend rejects the request.
  final Future<bool> Function(
      DateTime date, AvailableSlot slot, int rescheduleReasonId) onConfirm;

  const RescheduleSheet({
    super.key,
    required this.patient,
    required this.onFetchSlots,
    required this.onFetchReasons,
    required this.onConfirm,
  });

  /// Convenience launcher — call this from PatientCard's onReschedule.
  static Future<void> show(
      BuildContext context, {
        required AssignedPatient patient,
        required Future<List<AvailableSlot>> Function(DateTime) onFetchSlots,
        required Future<List<RescheduleReason>> Function() onFetchReasons,
        required Future<bool> Function(DateTime, AvailableSlot, int) onConfirm,
      }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => RescheduleSheet(
        patient: patient,
        onFetchSlots: onFetchSlots,
        onFetchReasons: onFetchReasons,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  State<RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<RescheduleSheet> {
  late final List<DateTime> _dates;

  List<AvailableSlot> _slots = const <AvailableSlot>[];
  List<RescheduleReason> _reasons = const <RescheduleReason>[];

  DateTime? _selectedDate;
  AvailableSlot? _selectedSlot;
  RescheduleReason? _selectedReason;

  bool _loadingSlots = false;
  bool _loadingReasons = false;
  bool _reasonExpanded = false;
  bool _submitting = false;
  String? _slotsError;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    // Next 3 days, starting tomorrow — no same-day reschedule.
    _dates = List.generate(
      7,
          (i) => DateTime(today.year, today.month, today.day + i  ),
    );
    // Preselect the first day so its slots start loading immediately.
    _selectedDate = _dates.first;
    _loadSlots(_dates.first);
    _loadReasons();
  }

  bool get _canConfirm =>
      _selectedDate != null &&
      _selectedSlot != null &&
      _selectedReason != null &&
      !_loadingSlots &&
      !_loadingReasons &&
      !_submitting;

  void _selectDate(DateTime date) {
    if (_selectedDate != null &&
        _selectedDate!.year == date.year &&
        _selectedDate!.month == date.month &&
        _selectedDate!.day == date.day) {
      return;
    }
    setState(() => _selectedDate = date);
    _loadSlots(date);
  }

  Future<void> _loadSlots(DateTime date) async {
    setState(() {
      _selectedSlot = null;
      _loadingSlots = true;
      _slotsError = null;
    });
    try {
      final slots = await widget.onFetchSlots(date);
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _loadingSlots = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _slots = const <AvailableSlot>[];
        _loadingSlots = false;
        _slotsError =
            'We could not load the slots for this date. Choose another '
                'date or try again.';
      });
    }
  }

  Future<void> _loadReasons() async {
    setState(() {
      _loadingReasons = true;
      _reasons = const <RescheduleReason>[];
    });
    try {
      final reasons = await widget.onFetchReasons();
      if (!mounted) return;
      setState(() {
        _reasons = reasons;
        _loadingReasons = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _reasons = const <RescheduleReason>[];
        _loadingReasons = false;
      });
    }
  }

  Future<void> _handleConfirm() async {
    if (!_canConfirm) return;
    setState(() => _submitting = true);
    try {
      final ok = await widget.onConfirm(
        _selectedDate!,
        _selectedSlot!,
        _selectedReason!.id,
      );
      if (ok && mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [

                _buildHeader(),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      _buildPatientSummary(),
                      const SizedBox(height: 20),
                      _buildReasonSection(),
                      const SizedBox(height: 24),
                      _sectionTitle('Select new date'),
                      const SizedBox(height: 10),
                      _buildDateStrip(),
                      const SizedBox(height: 24),
                      _sectionTitle('Select time slot'),
                      const SizedBox(height: 10),
                      _buildSlotGrid(),
                    ],
                  ),
                ),
                _buildConfirmBar(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDragHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Reschedule Visit',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textQuaternary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  /// Condensed read-only version of PatientCard's identity block —
  /// gives context without repeating the full action row.
  Widget _buildPatientSummary() {
    final p = widget.patient;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCardAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Visit type — directly against top/right border
          Align(
            alignment: Alignment.topLeft,
            child: VisitTypeBadge(
              visitType: p.visitType,
            ),
          ),

          // Patient content gets its own padding
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 1, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary100,
                  backgroundImage: p.avatarUrl != null
                      ? NetworkImage(p.avatarUrl!)
                      : null,
                  child: p.avatarUrl == null
                      ? Text(
                    p.name.isNotEmpty
                        ? p.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.primary800,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                      : null,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),

                      Text(
                        p.orderId,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Row(
                        children: [
                          const Icon(
                            Icons.event_outlined,
                            size: 13,
                            color: AppColors.purple,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            p.slotDateTime != null
                                ? 'Current: ${DateFormat('dd MMM, hh:mm a').format(p.slotDateTime!)}'
                                : 'Current: Not set',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
  );

  Widget _buildDateStrip() {
    return SizedBox(
      height: 74,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _dates.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final date = _dates[index];
                final isSelected = _selectedDate != null &&
                    _selectedDate!.year == date.year &&
                    _selectedDate!.month == date.month &&
                    _selectedDate!.day == date.day;

                return _DateChip(
                  date: date,
                  isSelected: isSelected,
                  onTap: () => _selectDate(date),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          _CalendarButton(onTap: _openCalendarPicker),
        ],
      ),
    );
  }

  Future<void> _openCalendarPicker() async {
    HapticFeedback.selectionClick();
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,

      builder: (_) => _CalendarSheet(initialDate: _selectedDate ?? DateTime.now()),
    );
    if (picked != null) {
      _selectDate(picked);
    }
  }

  Widget _buildSlotGrid() {
    if (_loadingSlots) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 26),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      );
    }

    if (_slotsError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.amberLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.amberBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _slotsError!,
              style: const TextStyle(fontSize: 12, height: 1.45),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _selectedDate == null
                  ? null
                  : () => _loadSlots(_selectedDate!),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    if (_slots.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCardAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 18,
              color: AppColors.textTertiary,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'No slots available for this date. Please pick another date.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _slots.map((slot) {
        final isSelected = _selectedSlot?.slotId == slot.slotId;
        return GestureDetector(
          onTap: () => setState(() => _selectedSlot = slot),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.accentGradient : null,
              color: isSelected ? null : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.transparent : AppColors.border,
              ),
            ),
            child: Text(
              slot.timeSlot,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConfirmBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: _canConfirm ? AppColors.accentGradient : null,
            color: _canConfirm ? null : AppColors.grayLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: _canConfirm ? _handleConfirm : null,
              child: Center(
                child: _submitting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                )
                    : Text(
                  'Confirm Reschedule',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: _canConfirm ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Reason for reschedule'),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _loadingReasons || _reasons.isEmpty
              ? null
              : () => setState(() => _reasonExpanded = !_reasonExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _reasonExpanded ? AppColors.primary700 : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _loadingReasons
                      ? const Text(
                    'Loading reasons...',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                      : Text(
                    _selectedReason?.reason ?? 'Select a reason',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _selectedReason != null
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                    ),
                  ),
                ),
                if (_loadingReasons)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 180),
                    turns: _reasonExpanded ? 0.5 : 0,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (!_loadingReasons && _reasons.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 14, color: AppColors.textTertiary),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Could not load reasons. Pull down to refresh and try again.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary),
                  ),
                ),
              ],
            ),
          ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: _reasonExpanded && _reasons.isNotEmpty
              ? Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: AppColors.bgCardAlt,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _reasons.map((reason) {
                final isSelected = _selectedReason?.id == reason.id;
                final isLast = reason == _reasons.last;
                return InkWell(
                  onTap: () => setState(() {
                    _selectedReason = reason;
                    _reasonExpanded = false;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      border: isLast
                          ? null
                          : const Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            reason.reason,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.primary700
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_rounded, size: 18, color: AppColors.primary700),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}class _DateChip extends StatefulWidget {
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateChip({
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_DateChip> createState() => _DateChipState();
}

class _DateChipState extends State<_DateChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 56,
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.accentGradient : null,
            color: isSelected ? null : AppColors.grayLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? Colors.transparent : AppColors.border,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
                : null,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('EEE').format(widget.date).toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white70 : AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('d').format(widget.date),
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Text(
                DateFormat('MMM').format(widget.date),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white70 : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CalendarButton({required this.onTap});

  @override
  State<_CalendarButton> createState() => _CalendarButtonState();
}

class _CalendarButtonState extends State<_CalendarButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          width: 56,
          height: 74,
          decoration: BoxDecoration(
            color: AppColors.grayLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.calendar_month_rounded,
            size: 22,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}


class _CalendarSheet extends StatelessWidget {
  final DateTime initialDate;
  const _CalendarSheet({required this.initialDate});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 40),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppColors.accent,
                ),
              ),
              child: CalendarDatePicker(
                initialDate: initialDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
                onDateChanged: (date) => Navigator.of(context).pop(date),
              ),
            ),
          ],
        ),
      ),
    );
  }
}