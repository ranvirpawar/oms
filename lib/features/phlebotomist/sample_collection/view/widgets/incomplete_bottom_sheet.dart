import 'package:flutter/material.dart';

import '../../../../../theme/app_colors.dart';
import '../../controller/sample_collection_controller.dart';
import '../../model/barcode_formatter.dart';
import '../../model/sample_collection_models.dart';

class IncompleteTestsBottomSheet extends StatefulWidget {
  final SampleBarcodeEntry entry;
  final List<IncompleteReasonOption> reasonOptions;
  /// Full reconciliation: whatever map you pass back IS the new state for
  /// this entry — empty map means "clear everything, nothing incomplete".
  final void Function(Map<int, TestIncompleteInfo> testInfos) onConfirm;

  const IncompleteTestsBottomSheet({
    super.key,
    required this.entry,
    required this.reasonOptions,
    required this.onConfirm,
  });

  @override
  State<IncompleteTestsBottomSheet> createState() => _IncompleteTestsBottomSheetState();
}

class _IncompleteTestsBottomSheetState extends State<IncompleteTestsBottomSheet> {
  late final Set<int> _selectedTestIds;
  final Map<int, IncompleteReasonOption?> _testReasons = {};
  final Map<int, TextEditingController> _testRemarksControllers = {};

  @override
  void initState() {
    super.initState();
    // Re-opening to edit should show exactly what's already flagged,
    // per-test reason and remarks included.
    _selectedTestIds = widget.entry.testIncompleteMap.keys.toSet();
    widget.entry.testIncompleteMap.forEach((testId, info) {
      _testReasons[testId] = info.reason;
      _testRemarksControllers[testId] = TextEditingController(text: info.remarks);
    });
  }

  @override
  void dispose() {
    for (final c in _testRemarksControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _allSelected =>
      widget.entry.tests.isNotEmpty && _selectedTestIds.length == widget.entry.tests.length;

  // Confirm is always allowed: an empty selection is a valid state
  // (means "clear everything"), a non-empty one just needs every
  // selected test to have a reason picked.
  bool get _canConfirm =>
      _selectedTestIds.isEmpty || _selectedTestIds.every((id) => _testReasons[id] != null);

  void _toggleTest(int testId) {
    setState(() {
      if (_selectedTestIds.contains(testId)) {
        _selectedTestIds.remove(testId);
        _testReasons.remove(testId);
        _testRemarksControllers.remove(testId)?.dispose();
      } else {
        _selectedTestIds.add(testId);
        _testRemarksControllers[testId] = TextEditingController();
      }
    });
  }

  void _toggleAll(bool selectAll) {
    setState(() {
      if (selectAll) {
        for (final t in widget.entry.tests) {
          _selectedTestIds.add(t.testId);
          _testRemarksControllers.putIfAbsent(t.testId, () => TextEditingController());
        }
      } else {
        _selectedTestIds.clear();
        _testReasons.clear();
        for (final c in _testRemarksControllers.values) {
          c.dispose();
        }
        _testRemarksControllers.clear();
      }
    });
  }

  Future<void> _pickReason(int testId) async {
    final picked = await showModalBottomSheet<IncompleteReasonOption>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ReasonPickerSheet(
        options: widget.reasonOptions,
        selected: _testReasons[testId],
      ),
    );
    if (picked != null) {
      setState(() => _testReasons[testId] = picked);
    }
  }

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
        ),
    };
    widget.onConfirm(result);
    Navigator.of(context).pop();
  }
  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        // Compute this INSIDE the builder, and use it for content padding,
        // not for shrinking the sheet's own layout constraints.
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;

        return Container(
          decoration: const BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // ---- Fixed header ---- (unchanged)
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
                  // Extra bottom padding = keyboard height, so a focused
                  // "note" field scrolls fully clear of the keyboard.
                  padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottomInset),
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

              // ---- Fixed footer, lifted above the keyboard ----
              Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Container(
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

/// One test row: checkbox + name, and — only when checked — its own
/// reason dropdown and an optional note, right underneath.
class _TestRow extends StatelessWidget {
  final TestInfo test;
  final bool isSelected;
  final IncompleteReasonOption? reason;
  final TextEditingController? remarksController;
  final bool showApplyToAll;
  final VoidCallback onToggle;
  final VoidCallback onPickReason;
  final VoidCallback onApplyToAll;

  const _TestRow({
    required this.test,
    required this.isSelected,
    required this.reason,
    required this.remarksController,
    required this.showApplyToAll,
    required this.onToggle,
    required this.onPickReason,
    required this.onApplyToAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  size: 20,
                  color: isSelected ? AppColors.redText : AppColors.textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        test.testName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                      ),
                      if (test.testCode.isNotEmpty)
                        Text(
                          test.testCode,
                          style: const TextStyle(fontSize: 10.5, color: AppColors.textTertiary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isSelected)
          Padding(
            padding: const EdgeInsets.only(left: 30, bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: onPickReason,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.grayLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: reason == null ? AppColors.border : AppColors.primary800),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            reason?.reason ?? 'Select a reason',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: reason == null ? AppColors.textMuted : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
                if (reason != null && showApplyToAll)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: TextButton(
                      onPressed: onApplyToAll,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: const Size(0, 28),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Use this reason for all selected', style: TextStyle(fontSize: 11.5)),
                    ),
                  ),
                const SizedBox(height: 6),
                if (remarksController != null)
                  TextField(
                    controller: remarksController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Add a note (optional)',
                      filled: true,
                      fillColor: AppColors.grayLight,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Nested picker sheet for a single test's reason — same shape as the old
/// _ReasonPicker sheet, checkmark on the selected item.
class _ReasonPickerSheet extends StatelessWidget {
  final List<IncompleteReasonOption> options;
  final IncompleteReasonOption? selected;

  const _ReasonPickerSheet({required this.options, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Select reason', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: options.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = selected?.reasonId == option.reasonId;
                return ListTile(
                  title: Text(option.reason, style: const TextStyle(fontSize: 13.5)),
                  trailing: isSelected ? const Icon(Icons.check_rounded, color: AppColors.primary800) : null,
                  onTap: () => Navigator.of(context).pop(option),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}