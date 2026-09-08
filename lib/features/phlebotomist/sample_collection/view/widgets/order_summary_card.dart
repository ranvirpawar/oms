import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../../theme/app_colors.dart';
import '../../../patient_queue/model/patient_queue_model.dart';
import '../../model/sample_collection_models.dart';
import '../order_confirmation_screen.dart';

class OrderPatientSummaryCard extends StatefulWidget {
  final String name;
  final String? avatarUrl;
  final String orderId;

  /// e.g. "34 • Male" — null when that detail isn't available yet.
  final String? subtitle;

  /// Pre-formatted slot label, e.g. "08 Sep 2026, 10:30 AM".
  final String? slotLabel;

  final bool fastingRequired;
  final String? fastingNote;
  final List<String> specialInstructions;
  final List<SummarySampleGroup> sampleGroups;

  final bool initiallyExpanded;

  /// True when this card floats over the live map — gets a glassy,
  /// elevated treatment instead of the flat in-list card style.
  final bool floating;

  const OrderPatientSummaryCard({
    super.key,
    required this.name,
    this.avatarUrl,
    required this.orderId,
    this.subtitle,
    this.slotLabel,
    this.fastingRequired = false,
    this.fastingNote,
    this.specialInstructions = const [],
    this.sampleGroups = const [],
    this.initiallyExpanded = false,
    this.floating = false,
  });

  /// Adapts the lightweight `AssignedPatient` model — all that's available
  /// before order details are fetched (not-accepted / needs-route-start /
  /// en-route states).
  factory OrderPatientSummaryCard.fromAssignedPatient({
    required AssignedPatient patient,
    bool initiallyExpanded = false,
    bool floating = false,
  }) {
    return OrderPatientSummaryCard(
      name: patient.name,
      avatarUrl: patient.avatarUrl,
      orderId: patient.orderId.toString(),
      slotLabel: patient.slotDateTime != null
          ? DateFormat('dd MMM yyyy, hh:mm a').format(patient.slotDateTime!)
          : null,
      sampleGroups: patient.tests.isEmpty
          ? const []
          : [
        SummarySampleGroup(
          sampleType: 'Tests',
          tests: patient.tests.map((t) => SummaryTestItem(t)).toList(),
        ),
      ],
      initiallyExpanded: initiallyExpanded,
      floating: floating,
    );
  }

  /// Adapts the full `OrderConfirmationDetails` fetched after arrival —
  /// includes fasting/special instructions and per-sample-type volumes
  /// and test codes.
  factory OrderPatientSummaryCard.fromOrder({
    required OrderConfirmationDetails order,
    bool initiallyExpanded = true,
    bool floating = false,
  }) {
    return OrderPatientSummaryCard(
      name: order.patient.name,
      avatarUrl: order.patient.photoUrl,
      orderId: order.orderId,
      subtitle: '${order.patient.age} • ${order.patient.gender}',
      slotLabel: order.slotDateTime,
      fastingRequired: order.fastingRequired,
      fastingNote: order.fastingNote,
      specialInstructions: {
        for (final s in order.specialInstructions) s.instruction,
      }.toList(),
      sampleGroups: order.sampleRequirements
          .map(
            (r) => SummarySampleGroup(
          sampleType: r.sampleType,
          volume: r.volumeRequiredMl,
          tests: r.tests
              .map((t) => SummaryTestItem(t.testName, t.testCode))
              .toList(),
        ),
      )
          .toList(),
      initiallyExpanded: initiallyExpanded,
      floating: floating,
    );
  }

  @override
  State<OrderPatientSummaryCard> createState() =>
      _OrderPatientSummaryCardState();
}

class _OrderPatientSummaryCardState extends State<OrderPatientSummaryCard> {
  late bool _expanded = widget.initiallyExpanded;
  bool _pressed = false;

  int get _testCount =>
      widget.sampleGroups.fold(0, (sum, g) => sum + g.tests.length);

  void _toggle() {
    HapticFeedback.lightImpact();
    setState(() => _expanded = !_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final hasBody = widget.fastingRequired ||
        (widget.fastingNote?.isNotEmpty ?? false) ||
        widget.specialInstructions.isNotEmpty ||
        widget.sampleGroups.isNotEmpty;

    final card = Container(
      decoration: BoxDecoration(
        color: widget.floating
            ? AppColors.bgCard.withOpacity(0.92)
            : AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.shadowSm,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTapDown: hasBody ? (_) => setState(() => _pressed = true) : null,
              onTapUp: hasBody ? (_) => setState(() => _pressed = false) : null,
              onTapCancel: hasBody ? () => setState(() => _pressed = false) : null,
              onTap: hasBody ? _toggle : null,
              behavior: HitTestBehavior.opaque,
              child: AnimatedScale(
                scale: _pressed ? 0.985 : 1.0,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: _Header(
                    name: widget.name,
                    avatarUrl: widget.avatarUrl,
                    orderId: widget.orderId,
                    subtitle: widget.subtitle,
                    slotLabel: widget.slotLabel,
                    testCount: _testCount,
                    expanded: _expanded,
                    showChevron: hasBody,
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: !_expanded || !hasBody
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: _Body(
                  fastingRequired: widget.fastingRequired,
                  fastingNote: widget.fastingNote,
                  specialInstructions: widget.specialInstructions,
                  sampleGroups: widget.sampleGroups,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!widget.floating) return card;

    // Floating (map-overlay) variant: subtle extra elevation so it reads
    // as sitting above the map rather than embedded in a list.
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: card,
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final String orderId;
  final String? subtitle;
  final String? slotLabel;
  final int testCount;
  final bool expanded;
  final bool showChevron;

  const _Header({
    required this.name,
    required this.avatarUrl,
    required this.orderId,
    required this.subtitle,
    required this.slotLabel,
    required this.testCount,
    required this.expanded,
    required this.showChevron,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primary100,
          backgroundImage: (avatarUrl?.isNotEmpty ?? false)
              ? NetworkImage(avatarUrl!)
              : null,
          child: (avatarUrl?.isNotEmpty ?? false)
              ? null
              : Text(
            name.isNotEmpty ? name.trim()[0].toUpperCase() : '?',
            style: const TextStyle(
              color: AppColors.primary800,
              fontWeight: FontWeight.w700,
              fontSize: 17,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle != null && subtitle!.isNotEmpty
                    ? '$subtitle • Order #$orderId'
                    : 'Order #$orderId',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textTertiary,
                ),
              ),
              if (slotLabel != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: AppColors.blueText,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        slotLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.blueText,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        if (showChevron) ...[
          const SizedBox(width: 8),
          if (!expanded && testCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.emerald50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$testCount test${testCount == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.greenText,
                ),
              ),
            ),
          AnimatedRotation(
            turns: expanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.textTertiary,
              size: 22,
            ),
          ),
        ],
      ],
    );
  }
}
class _Body extends StatefulWidget {
  final bool fastingRequired;
  final String? fastingNote;
  final List<String> specialInstructions;
  final List<SummarySampleGroup> sampleGroups;

  const _Body({
    required this.fastingRequired,
    required this.fastingNote,
    required this.specialInstructions,
    required this.sampleGroups,
  });

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> {
  bool _instructionsExpanded = true; // start expanded (change to false if you prefer collapsed)

  @override
  Widget build(BuildContext context) {
    final hasInstructions =
        (widget.fastingRequired && (widget.fastingNote?.isNotEmpty ?? false)) ||
            widget.specialInstructions.isNotEmpty;
    final testCount =
    widget.sampleGroups.fold(0, (sum, g) => sum + g.tests.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 20),

        if (widget.sampleGroups.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tests ($testCount)',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (widget.sampleGroups.length > 1 ||
                  widget.sampleGroups.first.sampleType != 'Tests')
                Text(
                  '${widget.sampleGroups.length} sample${widget.sampleGroups.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ..._buildGroups(),
        ],

        if (hasInstructions) ...[
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.amberLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.amberBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tappable header (keeps the original look + chevron)
                InkWell(
                  onTap: () {
                    setState(() {
                      _instructionsExpanded = !_instructionsExpanded;
                    });
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: AppColors.amberText,
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Instructions',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        AnimatedRotation(
                          turns: _instructionsExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Collapsible content
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: _instructionsExpanded
                      ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.fastingRequired &&
                            (widget.fastingNote?.isNotEmpty ?? false)) ...[
                          Text(
                            widget.fastingNote!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                        for (final instruction
                        in widget.specialInstructions)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '•  ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    instruction,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  List<Widget> _buildGroups() {
    final widgets = <Widget>[];
    var serial = 0;
    for (var i = 0; i < widget.sampleGroups.length; i++) {
      final group = widget.sampleGroups[i];
      // Skip the redundant group-header row for the plain "Tests" fallback
      // (used when only a flat test-name list is available, pre-fetch).
      if (group.sampleType != 'Tests' || widget.sampleGroups.length > 1) {
        widgets.add(
          Row(
            children: [
              const Icon(
                Icons.science_outlined,
                size: 14,
                color: AppColors.tealText,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  group.volume.isNotEmpty
                      ? '${group.sampleType} • ${group.volume}'
                      : group.sampleType,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
        widgets.add(const SizedBox(height: 6));
      }
      for (final test in group.tests) {
        serial++;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
                  child: Text(
                    '$serial.',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    test.name,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (test.code?.isNotEmpty ?? false)
                  Text(
                    test.code!,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
        );
      }
      if (i != widget.sampleGroups.length - 1) {
        widgets.add(const SizedBox(height: 10));
      }
    }
    return widgets;
  }
}
/*
class _Body extends StatelessWidget {
  final bool fastingRequired;
  final String? fastingNote;
  final List<String> specialInstructions;
  final List<SummarySampleGroup> sampleGroups;

  const _Body({
    required this.fastingRequired,
    required this.fastingNote,
    required this.specialInstructions,
    required this.sampleGroups,
  });

  @override
  Widget build(BuildContext context) {
    final hasInstructions =
        (fastingRequired && (fastingNote?.isNotEmpty ?? false)) ||
            specialInstructions.isNotEmpty;
    final testCount = sampleGroups.fold(0, (sum, g) => sum + g.tests.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 20),

        if (sampleGroups.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tests ($testCount)',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (sampleGroups.length > 1 ||
                  sampleGroups.first.sampleType != 'Tests')
                Text(
                  '${sampleGroups.length} sample${sampleGroups.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textTertiary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ..._buildGroups(),
        ],
        if (hasInstructions) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.amberLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.amberBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 15,
                      color: AppColors.amberText,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Instructions',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (fastingRequired && (fastingNote?.isNotEmpty ?? false)) ...[
                  const SizedBox(height: 6),
                  Text(
                    fastingNote!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
                for (final instruction in specialInstructions)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '•  ',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            instruction,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  List<Widget> _buildGroups() {
    final widgets = <Widget>[];
    var serial = 0;
    for (var i = 0; i < sampleGroups.length; i++) {
      final group = sampleGroups[i];
      // Skip the redundant group-header row for the plain "Tests" fallback
      // (used when only a flat test-name list is available, pre-fetch).
      if (group.sampleType != 'Tests' || sampleGroups.length > 1) {
        widgets.add(
          Row(
            children: [
              const Icon(
                Icons.science_outlined,
                size: 14,
                color: AppColors.tealText,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  group.volume.isNotEmpty
                      ? '${group.sampleType} • ${group.volume}'
                      : group.sampleType,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
        widgets.add(const SizedBox(height: 6));
      }
      for (final test in group.tests) {
        serial++;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
                  child: Text(
                    '$serial.',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    test.name,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (test.code?.isNotEmpty ?? false)
                  Text(
                    test.code!,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
        );
      }
      if (i != sampleGroups.length - 1) {
        widgets.add(const SizedBox(height: 10));
      }
    }
    return widgets;
  }
}*/
