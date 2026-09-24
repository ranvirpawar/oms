import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../../theme/app_colors.dart';
// Adjust this import to wherever CustomAppBar actually lives in your project
// (mirroring the widget used in OtpVerificationScreen).
import '../../../../utils/widgets/custom_appbar.dart';
import '../controller/order_confirmation_controller.dart';
import '../model/pre_collection_checklist.dart';
import '../model/sample_collection_models.dart';

/// ----------------------------------------------------------------------
/// Design tokens (local to this screen — pull from a shared AppRadii /
/// AppSpacing if your project already has one).
/// ----------------------------------------------------------------------
class _R {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 18.0;
  static const pill = 999.0;
}

class _S {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
}

BoxShadow get _cardShadow => BoxShadow(
  color: Colors.black.withOpacity(0.05),
  blurRadius: 18,
  offset: const Offset(0, 6),
);

/// ----------------------------------------------------------------------
/// Screen
/// ----------------------------------------------------------------------
class CollectionChecklistScreen extends GetView<OrderConfirmationController> {
  const CollectionChecklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grayLight,
      appBar: const CustomAppBar(title: 'Pre-Collection Checklist'),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoadingChecklist.value) return const _LoadingSkeleton();
          if (controller.checklistError.value.isNotEmpty) {
            return _ErrorState(
              message: controller.checklistError.value,
              onRetry: controller.fetchChecklist,
            );
          }
          final regular = controller.regularItems;
          final hasFasting = controller.fastingLinkedItems.isNotEmpty;
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(_S.md, _S.md, _S.md, _S.lg),
                  itemCount: (hasFasting ? 1 : 0) + regular.length,
                  separatorBuilder: (_, __) => const SizedBox(height: _S.sm),
                  itemBuilder: (context, index) {
                    if (hasFasting && index == 0) {
                      return const _MealTimeCard();
                    }
                    final itemIndex = hasFasting ? index - 1 : index;
                    return _ChecklistCard(
                      index: itemIndex,
                      item: regular[itemIndex],
                    );
                  },
                ),
              ),
              const _SubmitBar(),
            ],
          );
        }),
      ),
    );
  }
}

/// ----------------------------------------------------------------------
/// Reusable press-feedback wrapper (scale + haptic)
/// ----------------------------------------------------------------------
class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, required this.onTap, this.haptic = true});
  final Widget child;
  final VoidCallback onTap;
  final bool haptic;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (widget.haptic) HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
class _ChecklistCard extends GetView<OrderConfirmationController> {
  const _ChecklistCard({required this.index, required this.item});
  final int index;
  final ChecklistItem item;

  @override
  Widget build(BuildContext context) {
    final delay = (index.clamp(0, 8)) * 40;
    final isYesNo = item.dataType == ChecklistDataType.yesNo;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 12),
            child: child,
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _S.md,
          vertical: isYesNo ? 12 : _S.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(_R.lg),
          boxShadow: [_cardShadow],
        ),
        child: isYesNo ? _compactYesNoRow() : _stackedLayout(),
      ),
    );
  }

  // Single-line: number • question • compact toggle
  Widget _compactYesNoRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _indexBadge(),
        const SizedBox(width: _S.sm),
        Expanded(
          child: Text(
            item.checklistName,
            softWrap: true,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
              height: 1.25,
            ),
          ),
        ),
        const SizedBox(width: _S.sm),
        _YesNoToggle(item: item),
      ],
    );
  }

  // Original stacked layout for date/time and free-text
  Widget _stackedLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _indexBadge(),
            const SizedBox(width: _S.sm),
            Expanded(
              child: Text(
                item.checklistName,
                softWrap: true,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: _S.sm + 4),
        _buildInput(),
      ],
    );
  }

  Widget _indexBadge() {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: AppColors.accent700.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '${index + 1}',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.accent700,
        ),
      ),
    );
  }

  Widget _buildInput() {
    if (item.isFastingReq) return const SizedBox.shrink();
    switch (item.dataType) {
      case ChecklistDataType.yesNo:
        return _YesNoToggle(item: item); // unreachable via _stackedLayout now, kept for safety
      case ChecklistDataType.dateTime:
        return _DateTimeField(item: item);
      case ChecklistDataType.unknown:
        return TextField(
          onChanged: (v) => controller.setChecklistAnswer(item.checklistId, v),
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            hintText: item.dataValueHint,
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13.5),
            filled: true,
            fillColor: AppColors.grayLight,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_R.sm),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_R.sm),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(_R.sm),
              borderSide: const BorderSide(color: AppColors.blue, width: 1.4),
            ),
          ),
        );
    }
  }
}

/// Compact fixed-width segmented Yes/No toggle — sized to sit inline
/// next to a question, not stretched full-width.
class _YesNoToggle extends GetView<OrderConfirmationController> {
  const _YesNoToggle({required this.item});
  final ChecklistItem item;

  static const double _width = 92;
  static const double _height = 32;

  @override
  Widget build(BuildContext context) {
    final isYes = item.value == 'Y';
    final isNo = item.value == 'N';
    final hasValue = isYes || isNo;
    final activeColor = isYes ? AppColors.success : AppColors.error;
    const segmentWidth = _width / 2;

    return Container(
      width: _width,
      height: _height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.grayLight,
        borderRadius: BorderRadius.circular(_R.pill),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: !hasValue
                ? Alignment.center
                : isYes
                ? Alignment.centerLeft
                : Alignment.centerRight,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: hasValue ? 1 : 0,
              child: Container(
                width: segmentWidth - 3,
                height: _height - 6,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(_R.pill - 2),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withOpacity(0.28),
                      blurRadius: 6,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(child: _segment(label: 'Yes', isActive: isYes, onTap: () {
                HapticFeedback.selectionClick();
                controller.setChecklistAnswer(item.checklistId, 'Y');
              })),
              Expanded(child: _segment(label: 'No', isActive: isNo, onTap: () {
                HapticFeedback.selectionClick();
                controller.setChecklistAnswer(item.checklistId, 'N');
              })),
            ],
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedDefaultTextStyle(
        duration: const Duration(milliseconds: 160),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isActive ? Colors.white : AppColors.textMuted,
        ),
        child: Center(child: Text(label)),
      ),
    );
  }
}

/// ----------------------------------------------------------------------
/// Date & time field — opens an iOS wheel picker in a bottom sheet
/// ----------------------------------------------------------------------
class _DateTimeField extends GetView<OrderConfirmationController> {
  const _DateTimeField({required this.item});
  final ChecklistItem item;
  static final DateFormat _format = DateFormat('dd-MM-yyyy HH:mm');

  Future<void> _open(BuildContext context) async {
    final initial = item.value.isEmpty
        ? DateTime.now()
        : _parseChecklistDt(item.value);
    final result = await _pickDateTime(context, initial);
    if (result == null) return;
    controller.setChecklistAnswer(item.checklistId, _format.format(result));
  }

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      haptic: false,
      onTap: () => _open(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.grayLight,
          borderRadius: BorderRadius.circular(_R.sm),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppColors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.access_time_rounded,
                  size: 15, color: AppColors.blue),
            ),
            const SizedBox(width: _S.sm + 2),
            Expanded(
              child: Text(
                item.value.isEmpty ? 'Select date & time' : item.value,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: item.value.isEmpty
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
Future<DateTime?> _pickDateTime(BuildContext context, DateTime initial) async {
  final now = DateTime.now();
  final earliest = now.subtract(const Duration(days: 2));
  var pending = initial.isBefore(earliest)
      ? earliest
      : (initial.isAfter(now) ? now : initial);

  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    showDragHandle: false,
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(_R.lg)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: _S.sm),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(_R.pill),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: _S.md, vertical: _S.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: const Text('Cancel',
                          style: TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600)),
                    ),
                    const Text('Select date & time',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    TextButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(sheetContext).pop(pending);
                      },
                      child: const Text('Done',
                          style: TextStyle(
                              color: AppColors.blue,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              SizedBox(
                height: 216,
                child: CupertinoTheme(
                  data: const CupertinoThemeData(
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle:
                      TextStyle(fontSize: 18, color: AppColors.textPrimary),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.dateAndTime,
                    initialDateTime: pending,
                    minimumDate: earliest,
                    maximumDate: now,
                    use24hFormat: true,
                    onDateTimeChanged: (value) {
                      HapticFeedback.selectionClick();
                      pending = value;
                    },

                  ),
                ),
              ),
              const SizedBox(height: _S.sm),
            ],
          ),
        ),
      );
    },
  );
}

DateTime _parseChecklistDt(String value) {
  try {
    return DateFormat('dd-MM-yyyy HH:mm').parse(value);
  } catch (_) {
    return DateTime.now();
  }
}
/// ----------------------------------------------------------------------
/// Bottom submit bar — mirrors OtpVerificationScreen's CTA styling
/// ----------------------------------------------------------------------
class _SubmitBar extends GetView<OrderConfirmationController> {
  const _SubmitBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        _S.md,
        _S.sm + 4,
        _S.md,
        _S.sm + 4 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Obx(() {
        final complete = controller.isChecklistComplete;
        final submitting = controller.isSubmittingChecklist.value;
        final enabled = complete && !submitting;
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent700,
              disabledBackgroundColor: AppColors.border,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              elevation: 0,
            ),
            onPressed: enabled ? controller.completeChecklist : null,
            child: submitting
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : Text(
              'Continue',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: enabled ? Colors.white : AppColors.textMuted,
              ),
            ),
          ),
        );
      }),
    );
  }
}
class _MealTimeCard extends GetView<OrderConfirmationController> {
  const _MealTimeCard();

  Future<void> _open(BuildContext context) async {
    final current = controller.mealTimeValue;
    final initial = current.isEmpty ? DateTime.now() : _parseChecklistDt(current);
    final result = await _pickDateTime(context, initial);
    if (result == null) return;
    final formatted = DateFormat('dd-MM-yyyy HH:mm').format(result);
    // Any linked row's id works — setChecklistAnswer fans it out to all.
    final targetId = controller.fastingLinkedItems.first.checklistId;
    controller.setChecklistAnswer(targetId, formatted);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final linked = controller.fastingLinkedItems;
      final value = controller.mealTimeValue;
      final conflicts = controller.mealTimeConflicts;

      return Container(
        padding: const EdgeInsets.all(_S.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(_R.lg),
          boxShadow: [_cardShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 1, right: _S.sm),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.restaurant_rounded,
                      size: 12, color: AppColors.blue),
                ),
                const Expanded(
                  child: Text(
                    'Last Meal Time',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Text(
                'Needed for: ${linked.map((i) => (i.testName?.isNotEmpty ?? false) ? i.testName! : i.checklistName).join(', ')}',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: _S.sm + 4),
            _Pressable(
              haptic: false,
              onTap: () => _open(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.grayLight,
                  borderRadius: BorderRadius.circular(_R.sm),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.access_time_rounded,
                          size: 15, color: AppColors.blue),
                    ),
                    const SizedBox(width: _S.sm + 2),
                    Expanded(
                      child: Text(
                        value.isEmpty ? 'Select last meal time' : value,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: value.isEmpty
                              ? AppColors.textMuted
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        size: 18, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            const Text(
              'Must be within the last 2 days',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),

            // Per-test result chips — only rendered once a time is set.
            if (value.isNotEmpty) ...[
              const SizedBox(height: _S.sm + 2),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: linked
                    .where((i) => i.fastingMinTime != null && i.fastingMaxTime != null)
                    .map((i) {
                  final label = (i.testName?.isNotEmpty ?? false) ? i.testName! : i.checklistName;
                  final ok = !conflicts.any((c) => c.checklistId == i.checklistId);
                  final color = ok ? AppColors.success : AppColors.error;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(_R.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(ok ? Icons.check_circle_rounded : Icons.error_rounded,
                            size: 12, color: color),
                        const SizedBox(width: 4),
                        Text(label,
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],

            // Detail + single ack, shown only when there's something to ack.
            if (conflicts.isNotEmpty) ...[
              const SizedBox(height: _S.sm),
              ...conflicts.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${c.label} needs ${_fmt(c.minHours)}–${_fmt(c.maxHours)}h since the meal — '
                      'logged gap is ${_fmt(c.hoursSinceMeal)}h, so it can\'t be collected '
                      'alongside the others at this timing.',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.warning, height: 1.4),
                ),
              )),
              const SizedBox(height: 4),
              _Pressable(
                onTap: () => controller.fastingAdvisoryAcknowledged.toggle(),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: controller.fastingAdvisoryAcknowledged.value
                            ? AppColors.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: AppColors.primary, width: 1.4),
                      ),
                      alignment: Alignment.center,
                      child: controller.fastingAdvisoryAcknowledged.value
                          ? const Icon(Icons.check, size: 12, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: _S.sm),
                    const Expanded(
                      child: Text(
                        "I've confirmed this timing with the patient",
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  String _fmt(double h) => h == h.roundToDouble() ? h.toStringAsFixed(0) : h.toStringAsFixed(2);
}
/// ----------------------------------------------------------------------
/// Loading skeleton — shaped like the real cards, not a bare spinner
/// ----------------------------------------------------------------------
class _LoadingSkeleton extends StatefulWidget {
  const _LoadingSkeleton();

  @override
  State<_LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<_LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = 0.5 + (_controller.value * 0.3);
        return ListView.separated(
          padding: const EdgeInsets.all(_S.md),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(height: _S.sm),
          itemBuilder: (context, index) {
            return Opacity(
              opacity: opacity,
              child: Container(
                height: 96,
                padding: const EdgeInsets.all(_S.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(_R.lg),
                  boxShadow: [_cardShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.grayLight,
                        borderRadius: BorderRadius.circular(_R.sm),
                      ),
                    ),
                    const SizedBox(height: _S.sm + 4),
                    Container(
                      width: 140,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.grayLight,
                        borderRadius: BorderRadius.circular(_R.pill),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// ----------------------------------------------------------------------
/// Error state — icon + message + retry CTA
/// ----------------------------------------------------------------------
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(_S.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.error_outline_rounded,
                  size: 28, color: AppColors.error),
            ),
            const SizedBox(height: _S.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textTertiary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: _S.md),
            _Pressable(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent700,
                  borderRadius: BorderRadius.circular(_R.pill),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
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