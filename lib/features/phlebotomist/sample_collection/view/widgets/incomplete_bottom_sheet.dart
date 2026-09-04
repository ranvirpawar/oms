import 'package:flutter/material.dart';

import '../../../../../theme/app_colors.dart';
import '../../controller/sample_collection_controller.dart';
import '../../model/sample_collection_models.dart';

/// Lets the phlebotomist pick exactly which tests under a sample can't be
/// run, and log one reason for the batch. Built for speed at the bedside:
/// tap the affected tests (or the "couldn't draw at all" shortcut), tap a
/// reason chip, confirm. Free text is optional, never required.
class IncompleteTestsBottomSheet extends StatefulWidget {
  final SampleBarcodeEntry entry;
  final List<IncompleteReasonOption> reasonOptions;
  final void Function(
      Set<int> testIds,
      IncompleteReasonOption reason,
      String remarks,
      ) onConfirm;

  const IncompleteTestsBottomSheet({
    super.key,
    required this.entry,
    required this.reasonOptions,
    required this.onConfirm,
  });

  @override
  State<IncompleteTestsBottomSheet> createState() =>
      _IncompleteTestsBottomSheetState();
}

class _IncompleteTestsBottomSheetState
    extends State<IncompleteTestsBottomSheet> {
  late final Set<int> _selectedTestIds;
  IncompleteReasonOption? _reason;
  final TextEditingController _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Re-opening to edit should show what's already flagged.
    _selectedTestIds = widget.entry.testIncompleteMap.keys.toSet();
    final existing = widget.entry.testIncompleteMap.values;
    if (existing.isNotEmpty) {
      _reason = existing.first.reason;
      _remarksController.text = existing.first.remarks;
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  bool get _allSelected =>
      widget.entry.tests.isNotEmpty &&
          _selectedTestIds.length == widget.entry.tests.length;

  void _toggleAll(bool selectAll) {
    setState(() {
      if (selectAll) {
        _selectedTestIds
          ..clear()
          ..addAll(widget.entry.tests.map((t) => t.testId));
      } else {
        _selectedTestIds.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
              const Text(
                'Which tests are affected?',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                '${entry.sampleType} • select every test this sample can\'t cover',
                style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _toggleAll(!_allSelected),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _allSelected
                        ? AppColors.redLight.withOpacity(0.4)
                        : AppColors.grayLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _allSelected
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        size: 20,
                        color: _allSelected ? AppColors.redText : AppColors.textMuted,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          "Couldn't collect this sample at all",
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 6),
              for (final test in entry.tests)
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() {
                    _selectedTestIds.contains(test.testId)
                        ? _selectedTestIds.remove(test.testId)
                        : _selectedTestIds.add(test.testId);
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          _selectedTestIds.contains(test.testId)
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          size: 20,
                          color: _selectedTestIds.contains(test.testId)
                              ? AppColors.redText
                              : AppColors.textMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                test.testName,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary),
                              ),
                              if (test.testCode.isNotEmpty)
                                Text(
                                  test.testCode,
                                  style: const TextStyle(
                                      fontSize: 10.5, color: AppColors.textTertiary),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              const Text('Reason',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.reasonOptions.map((r) {
                  final selected = _reason?.reasonId == r.reasonId;
                  return ChoiceChip(
                    label: Text(r.reason, style: const TextStyle(fontSize: 12)),
                    selected: selected,
                    onSelected: (_) => setState(() => _reason = r),
                    selectedColor: AppColors.primary100,
                    backgroundColor: AppColors.grayLight,
                    labelStyle: TextStyle(
                        color: selected
                            ? AppColors.primary800
                            : AppColors.textSecondary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _remarksController,
                maxLines: 2,
                style: const TextStyle(fontSize: 12.5),
                decoration: InputDecoration(
                  hintText: 'Add a note (optional)',
                  filled: true,
                  fillColor: AppColors.grayLight,
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent700,
                    shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 0,
                  ),
                  onPressed: (_selectedTestIds.isEmpty || _reason == null)
                      ? null
                      : () {
                    widget.onConfirm(
                      _selectedTestIds,
                      _reason!,
                      _remarksController.text.trim(),
                    );
                    Navigator.of(context).pop();
                  },
                  child: const Text('Confirm',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}