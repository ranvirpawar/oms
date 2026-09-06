import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_theme.dart';
import '../../controller/live_tracking_controller.dart';

/// Shared drill-down sheet — opened from both the Facilities tab (facility
/// card tap) and the Bags tab (bag card tap). It reads generic
/// title/subtitle fields off the controller rather than a FacilityModel,
/// since bag cards have no facility to point to.
class BagDrilldownSheet extends StatelessWidget {
  final LiveTrackingController controller;

  const BagDrilldownSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final title    = controller.drilldownTitle.value;
      final subtitle = controller.drilldownSubtitle.value;
      final loading  = controller.isDrilldownLoading.value;
      final error    = controller.drilldownError.value;
      final data     = controller.bagDrilldown.value;

      return DraggableScrollableSheet(
        initialChildSize: 0.62,
        minChildSize: 0.3,
        maxChildSize: 0.98,
        expand: false,
        builder: (_, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [

                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      // ── Header ─────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primary100,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.qr_code_2_rounded,
                              size: 22,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.sectionTitle.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                if (subtitle != null &&
                                    subtitle.trim().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: AppColors.textTertiary,
                            ),
                            splashRadius: 20,
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // ── Body states ─────────────────────────
                      if (loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                              strokeWidth: 2.4,
                            ),
                          ),
                        )
                      else if (error != null)
                        _ErrorState(message: error)
                      else if (data != null) ...[
                          const _SectionLabel(
                            icon: Icons.timeline_rounded,
                            label: 'Status Timeline',
                          ),
                          const SizedBox(height: 12),
                          if (data.statusEvents.isEmpty)
                            const _EmptyRow(text: 'No status updates yet.')
                          else
                            _StatusTimeline(events: data.statusEvents),

                          const SizedBox(height: 26),

                          const _SectionLabel(
                            icon: Icons.science_outlined,
                            label: 'Tube Contents',
                          ),
                          const SizedBox(height: 12),
                          if (data.tubeContents.isEmpty)
                            const _EmptyRow(text: 'No tube contents recorded.')
                          else
                            _TubeContentsPanel(
                              contents: data.tubeContents,
                              totalTubes: data.totalTubes,
                            ),
                        ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}

// ── Subwidgets ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textTertiary),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.sectionTitle.copyWith(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _EmptyRow extends StatelessWidget {
  final String text;

  const _EmptyRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySecondary,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.tealLight.withOpacity(0.0),
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Colors.red,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTextStyles.bodySecondary,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Vertical timeline with a connecting line; the most recent event is
/// highlighted as the current status, earlier ones render as completed.
/// Inverted vertical timeline displaying the latest status on top.
/// Limits initial records for a clean UI with a "See more" expansion toggle.
class _StatusTimeline extends StatefulWidget {
  final List<dynamic> events;

  const _StatusTimeline({required this.events});

  @override
  State<_StatusTimeline> createState() => _StatusTimelineState();
}

class _StatusTimelineState extends State<_StatusTimeline> {
  bool _isExpanded = false;
  static const int _initialLimit = 2; // Show top 2 records initially

  @override
  Widget build(BuildContext context) {
    if (widget.events.isEmpty) return const SizedBox.shrink();

    // 1. Invert the timeline so the latest update appears first
    final reversedEvents = widget.events.reversed.toList();

    final hasMore = reversedEvents.length > _initialLimit;
    final visibleEvents = _isExpanded || !hasMore
        ? reversedEvents
        : reversedEvents.take(_initialLimit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Timeline List ───────────────────────────────────────────────────
        Column(
          children: List.generate(visibleEvents.length, (i) {
            final isFirst = i == 0; // Latest item on top
            final isLastVisible = i == visibleEvents.length - 1;
            final event = visibleEvents[i];

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dot + connecting line
                  SizedBox(
                    width: 22,
                    child: Column(
                      children: [
                        Container(
                          width: isFirst ? 14 : 10,
                          height: isFirst ? 14 : 10,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: isFirst
                                ? AppColors.primary
                                : AppColors.primary.withOpacity(0.35),
                            shape: BoxShape.circle,
                            border: isFirst
                                ? Border.all(
                              color: AppColors.primary.withOpacity(0.25),
                              width: 4,
                            )
                                : null,
                          ),
                        ),
                        // Connector line (hidden after the last visible item)
                        if (!isLastVisible)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              color: AppColors.border,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Event Label & Details
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              event.status ?? '',
                              style: AppTextStyles.body.copyWith(
                                fontWeight:
                                isFirst ? FontWeight.w700 : FontWeight.w500,
                                color: isFirst
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          // "Latest" tag on the top entry for modern clarity
                          if (isFirst) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'LATEST',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),

        // ── Modern See More / See Less Toggle ──────────────────────────────
        if (hasMore) ...[
          Padding(
            padding: const EdgeInsets.only(left: 34, top: 2),
            child: InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isExpanded
                          ? 'Show less'
                          : 'See ${reversedEvents.length - _initialLimit} earlier update${(reversedEvents.length - _initialLimit) > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TubeContentsPanel extends StatelessWidget {
  final List<dynamic> contents;
  final int totalTubes;

  const _TubeContentsPanel({
    required this.contents,
    required this.totalTubes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 0.6),
      ),
      child: Column(
        children: [
          for (var i = 0; i < contents.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Tube Content & Count Row ───────────────────────
                  Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: AppColors.tealLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.science_outlined,
                          size: 14,
                          color: AppColors.tealText,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          contents[i].tubeContent ?? '',
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'x${contents[i].tubeCount ?? 0}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ── Facility Name & Ward Label Row ────────────────
                  if (contents[i].facilityName != null &&
                      contents[i].facilityName.toString().trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 36), // Aligned under tube title (26 icon + 10 spacing)
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_city_outlined,
                            size: 13,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${contents[i].facilityName}${contents[i].ward != null && contents[i].ward.toString().trim().isNotEmpty ? ' • Ward: ${contents[i].ward}' : ''}',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (i != contents.length - 1)
              const Divider(
                height: 1,
                thickness: 0.6,
                indent: 14,
                endIndent: 14,
                color: AppColors.border,
              ),
          ],

          // ── Total tubes footer strip ────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: const BoxDecoration(
              color: AppColors.primary100,
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(13),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total tubes',
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '$totalTubes',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}