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
          if (controller.isLoadingChecklist.value) {
            return const _LoadingSkeleton();
          }
          if (controller.checklistError.value.isNotEmpty) {
            return _ErrorState(
              message: controller.checklistError.value,
              onRetry: controller.fetchChecklist,
            );
          }
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    _S.md,
                    _S.md,
                    _S.md,
                    _S.lg,
                  ),
                  itemCount: controller.checklistItems.length,
                  separatorBuilder: (_, __) => const SizedBox(height: _S.sm),
                  itemBuilder: (context, index) {
                    final item = controller.checklistItems[index];
                    return _ChecklistCard(index: index, item: item);
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

/// ----------------------------------------------------------------------
/// Checklist card — one per item, staggered entrance
/// ----------------------------------------------------------------------
class _ChecklistCard extends GetView<OrderConfirmationController> {
  const _ChecklistCard({required this.index, required this.item});
  final int index;
  final ChecklistItem item;

  @override
  Widget build(BuildContext context) {
    final delay = (index.clamp(0, 8)) * 40;
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
        padding: const EdgeInsets.all(_S.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(_R.lg),
          boxShadow: [_cardShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item name — wrapped in Flexible so long labels never overflow
            // (this is what was producing the yellow/black overflow stripe).
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 1, right: _S.sm),
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
                ),
                Expanded(
                  child: Text(
                    item.checklistName,
                    softWrap: true,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: _S.sm + 4),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildInput() {
    switch (item.dataType) {
      case ChecklistDataType.yesNo:
        return _YesNoToggle(item: item);
      case ChecklistDataType.dateTime:
        return _DateTimeField(item: item);
      case ChecklistDataType.unknown:
      // Fallback for any future ChecklistDataType the backend adds —
      // at minimum let the phlebotomist type a free-text value rather
      // than silently blocking the checklist from ever completing.
        return TextField(
          onChanged: (v) =>
              controller.setChecklistAnswer(item.checklistId, v),
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            hintText: item.dataValueHint,
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13.5),
            filled: true,
            fillColor: AppColors.grayLight,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

/// ----------------------------------------------------------------------
/// Yes / No segmented pill toggle
/// ----------------------------------------------------------------------
class _YesNoToggle extends GetView<OrderConfirmationController> {
  const _YesNoToggle({required this.item});
  final ChecklistItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _pill(
            label: 'Yes',
            isActive: item.value == 'Y',
            color: AppColors.success,
            onTap: () => controller.setChecklistAnswer(item.checklistId, 'Y'),
          ),
        ),
        const SizedBox(width: _S.sm),
        Expanded(
          child: _pill(
            label: 'No',
            isActive: item.value == 'N',
            color: AppColors.error,
            onTap: () => controller.setChecklistAnswer(item.checklistId, 'N'),
          ),
        ),
      ],
    );
  }

  Widget _pill({
    required String label,
    required bool isActive,
    required Color color,
    required VoidCallback onTap,
  }) {
    return _Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.12) : AppColors.grayLight,
          borderRadius: BorderRadius.circular(_R.pill),
          border: Border.all(
            color: isActive ? color : AppColors.border,
            width: isActive ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: isActive ? color : AppColors.textMuted,
          ),
        ),
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

  // ChecklistDataValue hints "dd-mm-yyyy hh:mm" — mirror that format when
  // writing the value back so the payload matches what the server expects.
  static final DateFormat _format = DateFormat('dd-MM-yyyy HH:mm');

  DateTime _initialValue() {
    if (item.value.isEmpty) return DateTime.now();
    try {
      return _format.parse(item.value);
    } catch (_) {
      return DateTime.now();
    }
  }

  Future<void> _openPicker(BuildContext context) async {
    final now = DateTime.now();
    var pending = _initialValue();

    final result = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
                    horizontal: _S.md,
                    vertical: _S.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Text(
                        'Select date & time',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(sheetContext).pop(pending);
                        },
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            color: AppColors.blue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
                        dateTimePickerTextStyle: TextStyle(
                          fontSize: 18,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.dateAndTime,
                      initialDateTime: pending,
                      minimumDate: now.subtract(const Duration(days: 1)),
                      maximumDate: now.add(const Duration(days: 1)),
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

    if (result == null) return;
    controller.setChecklistAnswer(item.checklistId, _format.format(result));
  }

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      haptic: false,
      onTap: () => _openPicker(context),
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
            // Flexible so a long formatted date/time string wraps or
            // truncates instead of overflowing the row.
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