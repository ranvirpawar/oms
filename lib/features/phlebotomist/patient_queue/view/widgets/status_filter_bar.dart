import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../theme/app_colors.dart';
import '../../controller/patient_queue_controller.dart';
import '../../model/patient_queue_model.dart';
import 'emergency_badge.dart';
import 'priority_indicator.dart';

class StatusFilterBar extends StatelessWidget {
  final List<StatusFilterOption> filters;
  final PatientStatus? activeStatus;
  final ValueChanged<PatientStatus?> onFilterSelected;
  final bool isEmergencyActive;
  final int emergencyCount;
  final VoidCallback? onEmergencyToggle;
  final List<ClinicFilterOption> clinics;      // added
  final String? activeClinic;                  // added
  final ValueChanged<String?>? onClinicSelected; // added
  final VisitType activeVisitType;


  const StatusFilterBar({
    super.key,
    required this.filters,
    required this.activeStatus,
    required this.onFilterSelected,
    this.isEmergencyActive = false,
    this.emergencyCount = 0,
    this.onEmergencyToggle,
    this.clinics = const [],
    this.activeClinic,
    this.onClinicSelected,
    required this.activeVisitType,
  });

  @override
  Widget build(BuildContext context) {
    final showEmergencyChip = emergencyCount > 0 || isEmergencyActive;
    final showClinicChip =
        clinics.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            if (filters.isNotEmpty) ...[
              _FilterChip(
                label: filters.first.label,
                count: filters.first.count,
                isSelected: filters.first.status == activeStatus && !isEmergencyActive,
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (isEmergencyActive && onEmergencyToggle != null) {
                    onEmergencyToggle!();
                  }
                  onFilterSelected(null);
                },
              ),
              const SizedBox(width: 8),
            ],
            // Clinic dropdown — only shown when there's clinic data to filter by.
            if (showClinicChip) ...[

              _ClinicDropdownChip(
                clinics: clinics,
                activeClinic: activeClinic,
                onSelected: onClinicSelected ?? (_) {},
              ),
              const SizedBox(width: 8),
            ],

            if (showEmergencyChip) ...[
              _EmergencyFilterChip(
                count: emergencyCount,
                isSelected: isEmergencyActive,
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (onEmergencyToggle != null) {
                    onEmergencyToggle!();
                  }
                },
              ),
              const SizedBox(width: 8),
            ],

            for (int i = 1; i < filters.length; i++) ...[
              _FilterChip(
                label: filters[i].label,
                count: filters[i].count,
                isSelected: filters[i].status == activeStatus && !isEmergencyActive,
                onTap: () {
                  HapticFeedback.selectionClick();
                  if (isEmergencyActive && onEmergencyToggle != null) {
                    onEmergencyToggle!();
                  }
                  final selected = filters[i].status == activeStatus;
                  onFilterSelected(selected ? null : filters[i].status);
                },
              ),
              if (i < filters.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary700 : AppColors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _CountBadge(count: count, isSelected: isSelected),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.primary700
                      : AppColors.textSecondary,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.close_rounded,
                  size: 15,
                  color: AppColors.primary700,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyFilterChip extends StatefulWidget {
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _EmergencyFilterChip({
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_EmergencyFilterChip> createState() => _EmergencyFilterChipState();
}

class _EmergencyFilterChipState extends State<_EmergencyFilterChip>
    with SingleTickerProviderStateMixin {
  static const Color _emergencyRed = Color(0xFFB4413F);

  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? _emergencyRed : AppColors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CountBadge(
                      count: widget.count,
                      isSelected: isSelected,
                      selectedColor: _emergencyRed,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Emergency',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _emergencyRed,
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedPriorityBubble(
                      size: 5.5,
                      color: _emergencyRed,
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.close_rounded,
                        size: 15,
                        color: _emergencyRed,
                      ),
                    ],
                  ],
                ),

                // Shimmer sweep overlay — a translating gradient stripe,
                // no ShaderMask needed so it never occludes the content.
                // Shimmer sweep overlay — narrow, high-contrast "shine" band on a diagonal.
                Positioned.fill(
                  child: IgnorePointer(
                    child: ClipRect(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final bandWidth = width * 0.5;
                          return AnimatedBuilder(
                            animation: _shimmerController,
                            builder: (context, _) {
                              final t = _shimmerController.value; // 0 -> 1 -> 0
                              final dx = -bandWidth + ((width + bandWidth) * t);
                              return Transform.translate(
                                offset: Offset(dx, 0),
                                child: Transform.rotate(
                                  angle: -0.35, // slight diagonal for a glassy shine look
                                  child: Container(
                                    width: bandWidth,
                                    height: (constraints.maxHeight) * 2.2,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [

                                          Colors.white.withOpacity(0.0),
                                          Colors.white.withOpacity(0.85),
                                          Colors.white.withOpacity(0.0),
                                        ],
                                        stops: const [0.35, 0.5, 0.65],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final bool isSelected;
  final Color selectedColor;

  const _CountBadge({
    required this.count,
    required this.isSelected,
    this.selectedColor = AppColors.primary700,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? selectedColor : AppColors.grayLight,
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: isSelected ? Colors.white : AppColors.textTertiary,
          height: 1,
        ),
      ),
    );
  }
}



// Tune these to match whatever your date filter menu uses.
const double _kClinicMenuWidth = double.infinity;
const double _kClinicMenuGap = 6.0;
const double _kClinicScreenMargin = 8.0;

/// Chip that opens a clinic picker as an overlay popover anchored to itself
/// (grows out of the chip, like DateFilterTile) instead of a bottom sheet.
class _ClinicDropdownChip extends StatefulWidget {
  final List<ClinicFilterOption> clinics;
  final String? activeClinic;
  final ValueChanged<String?> onSelected;

  const _ClinicDropdownChip({
    required this.clinics,
    required this.activeClinic,
    required this.onSelected,
  });

  @override
  State<_ClinicDropdownChip> createState() => _ClinicDropdownChipState();
}

class _ClinicDropdownChipState extends State<_ClinicDropdownChip>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  OverlayEntry? _entry;
  late final AnimationController _anim;

  bool get _isOpen => _entry != null;

  // padding (6*2) + "All Clinics" row + one row per clinic (~40 each).
  // Only decides open-up-vs-down; the layout delegate clamps to real size.
  double get _estimatedMenuHeight =>
      12 + (widget.clinics.length + 1) * 40.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _entry?.remove();
    _entry = null;
    _anim.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    if (_isOpen) _removeOverlay(animate: false);
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    _isOpen ? _removeOverlay() : _showOverlay();
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    final tileBox = context.findRenderObject() as RenderBox?;
    if (overlayBox == null || tileBox == null || !tileBox.attached) return;

    final anchor = tileBox.localToGlobal(Offset.zero, ancestor: overlayBox) &
    tileBox.size;

    final media = MediaQuery.of(context);
    final bottomInset =
    math.max(media.padding.bottom, media.viewInsets.bottom);
    final spaceBelow = overlayBox.size.height -
        bottomInset -
        _kClinicScreenMargin -
        anchor.bottom;
    final spaceAbove = anchor.top - media.padding.top - _kClinicScreenMargin;
    final needed = _estimatedMenuHeight + _kClinicMenuGap;
    final openUp = spaceBelow < needed && spaceAbove > spaceBelow;

    _entry = OverlayEntry(
      builder: (_) => _ClinicMenu(
        anchor: anchor,
        openUp: openUp,
        anim: _anim,
        clinics: widget.clinics,
        activeClinic: widget.activeClinic,
        onSelect: (value) {
          HapticFeedback.selectionClick();
          widget.onSelected(value);
          _removeOverlay();
        },
        onDismiss: _removeOverlay,
      ),
    );
    overlay.insert(_entry!);
    _anim.forward(from: 0);
    setState(() {});
  }

  void _removeOverlay({bool animate = true}) {
    if (_entry == null) return;
    if (!animate) {
      _entry!.remove();
      _entry = null;
      if (mounted) setState(() {});
      return;
    }
    _anim.reverse().then((_) {
      _entry?.remove();
      _entry = null;
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.activeClinic != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        constraints: const BoxConstraints(maxWidth: 170),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: (isSelected || _isOpen)
                ? AppColors.primary700
                : AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_hospital_outlined,
              size: 14,
              color: (isSelected || _isOpen)
                  ? AppColors.primary700
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                widget.activeClinic ?? 'Clinic',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: (isSelected || _isOpen)
                      ? AppColors.primary700
                      : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 2),
            AnimatedRotation(
              turns: _isOpen ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: (isSelected || _isOpen)
                    ? AppColors.primary700
                    : AppColors.textSecondary,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 2),
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onSelected(null);
                },
                child: const Icon(Icons.close_rounded,
                    size: 15, color: AppColors.primary700),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Right-aligns the menu to the chip, below it (or above when [openUp]),
/// then clamps so it never leaves the safe area — mirrors DateFilterTile's
/// _MenuLayoutDelegate.
class _ClinicMenuLayoutDelegate extends SingleChildLayoutDelegate {
  final Rect anchor;
  final EdgeInsets safe;
  final bool openUp;

  const _ClinicMenuLayoutDelegate({
    required this.anchor,
    required this.safe,
    required this.openUp,
  });

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      maxWidth: math.max(
        0,
        constraints.maxWidth - safe.horizontal - _kClinicScreenMargin * 2,
      ),
      maxHeight: math.max(
        0,
        constraints.maxHeight - safe.vertical - _kClinicScreenMargin * 2,
      ),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final minX = safe.left + _kClinicScreenMargin;
    final maxX = math.max(
      minX,
      size.width - safe.right - _kClinicScreenMargin - childSize.width,
    );
    final x = (anchor.right - childSize.width).clamp(minX, maxX).toDouble();

    final minY = safe.top + _kClinicScreenMargin;
    final maxY = math.max(
      minY,
      size.height - safe.bottom - _kClinicScreenMargin - childSize.height,
    );
    final preferredY = openUp
        ? anchor.top - _kClinicMenuGap - childSize.height
        : anchor.bottom + _kClinicMenuGap;
    final y = preferredY.clamp(minY, maxY).toDouble();

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_ClinicMenuLayoutDelegate old) =>
      anchor != old.anchor || safe != old.safe || openUp != old.openUp;
}

class _ClinicMenu extends StatelessWidget {
  final Rect anchor;
  final bool openUp;
  final AnimationController anim;
  final List<ClinicFilterOption> clinics;
  final String? activeClinic;
  final ValueChanged<String?> onSelect;
  final VoidCallback onDismiss;

  const _ClinicMenu({
    required this.anchor,
    required this.openUp,
    required this.anim,
    required this.clinics,
    required this.activeClinic,
    required this.onSelect,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: anim,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );

    final media = MediaQuery.of(context);
    final safe = media.padding.copyWith(
      bottom: math.max(media.padding.bottom, media.viewInsets.bottom),
    );

    final clampedLeft =
        anchor.right - _kClinicMenuWidth < safe.left + _kClinicScreenMargin;
    final scaleOrigin = Alignment(
      clampedLeft ? -1 : 1,
      openUp ? 1 : -1,
    );

    final totalCount = clinics.fold<int>(0, (sum, c) => sum + c.count);
    // Cap the menu's own height so a long clinic list scrolls inside itself
    // rather than pushing off-screen; layout delegate clamps further anyway.
    final maxMenuHeight = media.size.height * 0.5;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDismiss,
            child: const ColoredBox(color: Colors.transparent),
          ),
        ),
        CustomSingleChildLayout(
          delegate: _ClinicMenuLayoutDelegate(
            anchor: anchor,
            safe: safe,
            openUp: openUp,
          ),
          child: FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: curved.drive(Tween(begin: 0.9, end: 1.0)),
              alignment: scaleOrigin,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: _kClinicMenuWidth,
                  constraints: BoxConstraints(maxHeight: maxMenuHeight),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border, width: 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ClinicMenuItem(
                          label: 'All Clinics',
                          count: totalCount,
                          selected: activeClinic == null,
                          onTap: () => onSelect(null),
                        ),
                        for (final clinic in clinics)
                          _ClinicMenuItem(
                            label: clinic.name,
                            count: clinic.count,
                            selected: activeClinic == clinic.name,
                            onTap: () => onSelect(clinic.name),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ClinicMenuItem extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _ClinicMenuItem({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary700.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? AppColors.primary700
                      : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary700.withOpacity(0.12)
                    : AppColors.grayLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.primary700
                      : AppColors.textTertiary,
                ),
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              Icon(Icons.check_rounded, size: 16, color: AppColors.primary700),
            ],
          ],
        ),
      ),
    );
  }
}
/*
class _ClinicDropdownChip extends StatelessWidget {
  final List<ClinicFilterOption> clinics;
  final String? activeClinic;
  final ValueChanged<String?> onSelected;

  const _ClinicDropdownChip({
    required this.clinics,
    required this.activeClinic,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = activeClinic != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          _openClinicPicker(context);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 170),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary700 : AppColors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_hospital_outlined,
                size: 14,
                color: isSelected ? AppColors.primary700 : AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  activeClinic ?? 'Clinic',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.primary700 : AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: isSelected ? AppColors.primary700 : AppColors.textSecondary,
              ),
              if (isSelected) ...[
                const SizedBox(width: 2),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelected(null);
                  },
                  child: const Icon(Icons.close_rounded, size: 15, color: AppColors.primary700),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _openClinicPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ClinicPickerSheet(
        clinics: clinics,
        activeClinic: activeClinic,
        onSelected: (clinic) {
          Navigator.of(sheetContext).pop();
          onSelected(clinic);
        },
      ),
    );
  }
}

class _ClinicPickerSheet extends StatelessWidget {
  final List<ClinicFilterOption> clinics;
  final String? activeClinic;
  final ValueChanged<String?> onSelected;

  const _ClinicPickerSheet({
    required this.clinics,
    required this.activeClinic,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final totalCount = clinics.fold<int>(0, (sum, c) => sum + c.count);

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        decoration: const BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Filter by clinic',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  _ClinicOptionTile(
                    label: 'All Clinics',
                    count: totalCount,
                    isSelected: activeClinic == null,
                    onTap: () => onSelected(null),
                  ),
                  for (final clinic in clinics)
                    _ClinicOptionTile(
                      label: clinic.name,
                      count: clinic.count,
                      isSelected: activeClinic == clinic.name,
                      onTap: () => onSelected(clinic.name),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClinicOptionTile extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _ClinicOptionTile({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary700 : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary700.withOpacity(0.1) : AppColors.grayLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary700 : AppColors.textTertiary,
                ),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primary700),
            ],
          ],
        ),
      ),
    );
  }
}*/
