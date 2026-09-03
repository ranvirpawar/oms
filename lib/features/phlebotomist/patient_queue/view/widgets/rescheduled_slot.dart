import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/view/widgets/visit_type_badge.dart';

import '../../../../../theme/app_colors.dart';
import '../../model/patient_queue_model.dart';

/// A single selectable time slot, e.g. 09:00–09:30.
class TimeSlot {
  final String start; // "09:00:00" - matches service's startTime format
  final String end;   // "09:30:00"
  final String label; // "9:00 AM"

  const TimeSlot({required this.start, required this.end, required this.label});
}

class RescheduleSheet extends StatefulWidget {
  final AssignedPatient patient;
  final Future<void> Function(DateTime date, String startTime, String endTime) onConfirm;

  const RescheduleSheet({
    super.key,
    required this.patient,
    required this.onConfirm,
  });

  /// Convenience launcher — call this from PatientCard's onReschedule.
  static Future<void> show(
      BuildContext context, {
        required AssignedPatient patient,
        required Future<void> Function(DateTime, String, String) onConfirm,
      }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => RescheduleSheet(patient: patient, onConfirm: onConfirm),
    );
  }

  @override
  State<RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<RescheduleSheet> {
  late final List<DateTime> _dates;
  late final List<TimeSlot> _slots;

  DateTime? _selectedDate;
  TimeSlot? _selectedSlot;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    // Next 14 days, starting tomorrow — no same-day reschedule.
    _dates = List.generate(
      3,
          (i) => DateTime(today.year, today.month, today.day + i + 1),
    );
    _slots = _buildSlots();
  }

  List<TimeSlot> _buildSlots() {
    final slots = <TimeSlot>[];
    for (int hour = 8; hour < 18; hour++) {
      for (final minute in [0, 30]) {
        final startMinutesTotal = hour * 60 + minute;
        final endMinutesTotal = startMinutesTotal + 30;
        String fmt(int total) {
          final h = (total ~/ 60).toString().padLeft(2, '0');
          final m = (total % 60).toString().padLeft(2, '0');
          return '$h:$m:00';
        }

        final startLabel = DateFormat('h:mm a').format(
          DateTime(0, 1, 1, hour, minute),
        );
        slots.add(TimeSlot(
          start: fmt(startMinutesTotal),
          end: fmt(endMinutesTotal),
          label: startLabel,
        ));
      }
    }
    return slots;
  }

  bool get _canConfirm => _selectedDate != null && _selectedSlot != null && !_submitting;

  Future<void> _handleConfirm() async {
    if (!_canConfirm) return;
    setState(() => _submitting = true);
    try {
      await widget.onConfirm(_selectedDate!, _selectedSlot!.start, _selectedSlot!.end);
      if (mounted) Navigator.of(context).pop();
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

          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 0),
              width: 56,
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.accentGradient : null,
                color: isSelected ? null : AppColors.grayLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? Colors.transparent : AppColors.border,
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(date).toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white70 : AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    DateFormat('MMM').format(date),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white70 : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlotGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _slots.map((slot) {
        final isSelected = _selectedSlot?.start == slot.start;
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
              slot.label,
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
}