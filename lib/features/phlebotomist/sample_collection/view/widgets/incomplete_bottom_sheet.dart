import 'package:flutter/material.dart';
import '../../../patient_queue/model/patient_queue_model.dart';
import 'test_reschedule_fields.dart';

import '../../../../../theme/app_colors.dart';
import '../../model/barcode_formatter.dart';
import '../../model/sample_collection_models.dart';

class IncompleteTestsBottomSheet extends StatefulWidget {
  final SampleBarcodeEntry entry;
  final List<IncompleteReasonOption> reasonOptions;
  final Future<List<AvailableSlot>> Function(DateTime) onFetchSlots;

  /// Saves existing collection plans without removing tests or appointments.
  final void Function(Map<int, TestIncompleteInfo> testInfos) onConfirm;

  const IncompleteTestsBottomSheet({
    super.key,
    required this.entry,
    required this.reasonOptions,
    required this.onFetchSlots,
    required this.onConfirm,
  });

  @override
  State<IncompleteTestsBottomSheet> createState() =>
      _IncompleteTestsBottomSheetState();
}

class _IncompleteTestsBottomSheetState
    extends State<IncompleteTestsBottomSheet> {
  late final Set<int> _selectedTestIds;
  final Map<int, IncompleteReasonOption?> _testReasons = {};
  final Map<int, TestIncompleteInfo> _testSchedules = {};
  final Map<int, TextEditingController> _testRemarksControllers = {};

  @override
  void initState() {
    super.initState();
    // Re-opening to edit should show exactly what's already flagged,
    // per-test reason and remarks included.
    _selectedTestIds = widget.entry.testIncompleteMap.keys.toSet();
    widget.entry.testIncompleteMap.forEach((testId, info) {
      _testReasons[testId] = info.reason;
      _testSchedules[testId] = info;
      _testRemarksControllers[testId] = TextEditingController(
        text: info.remarks,
      );
    });
  }

  @override
  void dispose() {
    for (final c in _testRemarksControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _canConfirm =>
      _selectedTestIds.isNotEmpty &&
      _selectedTestIds.every(
        (id) =>
            _testReasons[id] != null &&
            (widget.entry.testIncompleteMap[id]?.hasSchedule != true ||
                _testSchedules[id]?.hasSchedule == true),
      );

  void _applyReasonToAllSelected(int sourceId) {
    final reason = _testReasons[sourceId];
    if (reason == null) return;
    setState(() {
      for (final id in _selectedTestIds) {
        _testReasons[id] = reason;
      }
    });
  }

  void _confirm() {
    final result = <int, TestIncompleteInfo>{
      for (final id in _selectedTestIds)
        id: TestIncompleteInfo(
          reason: _testReasons[id]!,
          remarks: _testRemarksControllers[id]?.text.trim() ?? '',
          appointmentDate: _testSchedules[id]?.appointmentDate,
          slotId: _testSchedules[id]?.slotId,
          slotLabel: _testSchedules[id]?.slotLabel ?? '',
        ),
    };
    widget.onConfirm(result);
    Navigator.of(context).pop();
  }

  Widget _buildTestRow(TestInfo test) {
    final plan = _testSchedules[test.testId];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            test.testName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          TestRescheduleFields(
            key: ValueKey(test.testId),
            testName: test.testName,
            requireSchedule:
                widget.entry.testIncompleteMap[test.testId]?.hasSchedule ==
                true,
            reasonOptions: widget.reasonOptions,
            initialInfo: _testReasons[test.testId] == null
                ? null
                : TestIncompleteInfo(
                    reason: _testReasons[test.testId]!,
                    remarks: _testRemarksControllers[test.testId]?.text ?? '',
                    appointmentDate: plan?.appointmentDate,
                    slotId: plan?.slotId,
                    slotLabel: plan?.slotLabel ?? '',
                  ),
            onFetchSlots: widget.onFetchSlots,
            onChanged: (info) => setState(() {
              _testReasons[test.testId] = info.reason;
              _testSchedules[test.testId] = info;
            }),
          ),
          if (_testReasons[test.testId] != null && _selectedTestIds.length > 1)
            TextButton(
              onPressed: () => _applyReasonToAllSelected(test.testId),
              child: const Text(
                'Use this reason for all selected',
                style: TextStyle(fontSize: 11.5),
              ),
            ),
          /* Optional note field hidden for this review.
                  const SizedBox(height: 6),
                  TextField(
                    controller: _testRemarksControllers[test.testId],
                    minLines: 1,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Add a note (optional)',
                      filled: true,
                      fillColor: AppColors.grayLight,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  */
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,

      builder: (context, scrollController) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return Container(
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
                        'Rescheduled tests',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close review',
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
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
                  children: [
                    Text(
                      widget.entry.sampleType,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Review the reason and collection time agreed with the patient. Tap either field to change it.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final test in widget.entry.tests.where(
                      (test) => _selectedTestIds.contains(test.testId),
                    ))
                      _buildTestRow(test),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Container(
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
                        onPressed: _canConfirm ? _confirm : null,
                        child: const Text(
                          'Save changes',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /* @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // ---- Fixed header ----
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Which tests are affected?',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                            ),
                          ),
                          if (_selectedTestIds.isNotEmpty)
                            TextButton(
                              onPressed: () => _toggleAll(false),
                              style: TextButton.styleFrom(foregroundColor: AppColors.redText),
                              child: const Text('Clear all', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ),
                      Text(
                        '${entry.sampleType} • select every test this sample can\'t cover',
                        style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // ---- Scrollable body ----
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _toggleAll(!_allSelected),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: _allSelected ? AppColors.redLight.withOpacity(0.4) : AppColors.grayLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _allSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                  size: 20,
                                  color: _allSelected ? AppColors.redText : AppColors.textMuted,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    "Couldn't collect this sample at all",
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 6),

                        for (final test in entry.tests) ...[
                          _TestRow(
                            test: test,
                            isSelected: _selectedTestIds.contains(test.testId),
                            reason: _testReasons[test.testId],
                            remarksController: _testRemarksControllers[test.testId],
                            showApplyToAll: _selectedTestIds.length > 1,
                            onToggle: () => _toggleTest(test.testId),
                            onPickReason: () => _pickReason(test.testId),
                            onApplyToAll: () => _applyReasonToAllSelected(test.testId),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ],
                    ),
                  ),
                ),

                // ---- Fixed footer — never scrolls away ----
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  decoration: const BoxDecoration(
                    color: AppColors.bgCard,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent700,
                        disabledBackgroundColor: AppColors.accent700.withOpacity(0.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        elevation: 0,
                      ),
                      onPressed: _canConfirm ? _confirm : null,
                      child: Text(
                        _selectedTestIds.isEmpty ? 'Confirm (no flags)' : 'Confirm',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }*/
}
