import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../../theme/app_colors.dart';
import '../../../patient_queue/model/patient_queue_model.dart';
import '../../model/sample_collection_models.dart';
import '../order_confirmation_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../../theme/app_colors.dart';
import '../../../patient_queue/model/patient_queue_model.dart';
import '../../model/sample_collection_models.dart';
import '../order_confirmation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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
    final groups = <String, List<SummaryTestItem>>{};
    for (final t in patient.rawTests) {
      final sampleType = (t.sampleTypeName?.trim().isNotEmpty ?? false)
          ? t.sampleTypeName!.trim()
          : 'Other';
      groups
          .putIfAbsent(sampleType, () => [])
          .add(SummaryTestItem(t.testName, null, t.tubeContent));
    }

    return OrderPatientSummaryCard(
      name: patient.name,
      avatarUrl: patient.avatarUrl,
      orderId: patient.orderId.toString(),
      subtitle: 'Age ${patient.age} • ${patient.gender}',
      slotLabel: patient.slotDateTime != null
          ? DateFormat('dd MMM yyyy, hh:mm a').format(patient.slotDateTime!)
          : null,
      sampleGroups: groups.entries
          .map((e) => SummarySampleGroup(sampleType: e.key, tests: e.value))
          .toList(),
      initiallyExpanded: initiallyExpanded,
      floating: floating,
    );
  }

  /// Adapts the full `OrderConfirmationDetails` fetched after arrival —
  /// includes fasting/special instructions and per-sample-type volumes,
  /// test codes, and (where the API provides it) tube type.
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
                  .map(
                    (t) => SummaryTestItem(
                      t.testName,
                      t.testCode,
                      t.tubeTypes
                          .map((tt) => tt.tubeType.trim())
                          .firstWhere((s) => s.isNotEmpty, orElse: () => ''),
                    ),
                  )
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
    final hasBody =
        widget.fastingRequired ||
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
              onTapDown: hasBody
                  ? (_) => setState(() => _pressed = true)
                  : null,
              onTapUp: hasBody ? (_) => setState(() => _pressed = false) : null,
              onTapCancel: hasBody
                  ? () => setState(() => _pressed = false)
                  : null,
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
                        floating: widget.floating,
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

/// One sample-type group (e.g. "Blood • 5 ml") with its tests.
class SummarySampleGroup {
  final String sampleType;
  final String volume;
  final List<SummaryTestItem> tests;

  const SummarySampleGroup({
    required this.sampleType,
    this.volume = '',
    required this.tests,
  });
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
                    ? '• $subtitle \n• Order #$orderId'
                    : 'Order #$orderId',
                maxLines: 2,
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

// ============================================================================
// Body — modern tabular layout: Sample type (section) → Test name | Tube type
// ============================================================================

class _Body extends StatelessWidget {
  final bool fastingRequired;
  final String? fastingNote;
  final List<String> specialInstructions;
  final List<SummarySampleGroup> sampleGroups;
  final bool floating;

  const _Body({
    required this.fastingRequired,
    required this.fastingNote,
    required this.specialInstructions,
    required this.sampleGroups,
    required this.floating,

  });

  int get _testCount => sampleGroups.fold(0, (sum, g) => sum + g.tests.length);

  @override
  Widget build(BuildContext context) {

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: floating
            ? MediaQuery.of(context).size.height * 0.45 // Takes up to 45% of screen when floating
            : double.infinity, // Normal behavior when in a standard list
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(height: 20),

            if (sampleGroups.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tests ($_testCount)',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (sampleGroups.length > 1)
                    Text(
                      '${sampleGroups.length} samples',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              ...sampleGroups.map((g) => _SampleGroupTable(group: g)),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String text;

  const _InfoStrip({
    required this.icon,
    required this.color,
    required this.bg,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: color,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One sample-type section rendered as a compact "table": a muted section
/// header (sample type + volume) followed by rows of Test name | Tube type.
class _SampleGroupTable extends StatelessWidget {
  final SummarySampleGroup group;

  const _SampleGroupTable({required this.group});

  @override
  Widget build(BuildContext context) {
    final showSectionHeader =
        group.sampleType != 'Tests' || group.volume.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),

      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showSectionHeader)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              // color: AppColors.bgCard,
              child: Row(
                children: [
                  const Icon(
                    Icons.science_outlined,
                    size: 13,
                    color: AppColors.tealText,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      group.sampleType,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                  if (group.volume.isNotEmpty)
                    Text(
                      group.volume,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                      ),
                    ),
                ],
              ),
            ),

          // Column labels — only worth showing once there's more than one row,
          // otherwise it's noise.
          if (group.tests.length > 1)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: const Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'TEST NAME',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textTertiary,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'TUBE TYPE',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textTertiary,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          for (var i = 0; i < group.tests.length; i++)
            _TestRow(
              test: group.tests[i],
              fallbackSampleType: group.sampleType,
              isLast: i == group.tests.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TestRow extends StatelessWidget {
  final SummaryTestItem test;
  final String fallbackSampleType;
  final bool isLast;

  const _TestRow({
    required this.test,
    required this.fallbackSampleType,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final tube = TubeTypeInfo.resolve(
      explicitTubeType: test.tubeType,
      sampleType: fallbackSampleType,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.border, width: 0.75),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              test.name,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Align(
              alignment: Alignment.centerRight,
              child: _TubeTypeBadge(tube: tube),
            ),
          ),
        ],
      ),
    );
  }
}

class _TubeTypeBadge extends StatelessWidget {
  final TubeTypeInfo tube;

  const _TubeTypeBadge({required this.tube});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: tube.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: tube.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
              boxShadow: [
                BoxShadow(color: tube.color.withOpacity(0.4), blurRadius: 3),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              tube.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: tube.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Tube type model + fallback inference
// ============================================================================

class TubeTypeInfo {
  final String label;
  final Color color;

  const TubeTypeInfo(this.label, this.color);

  /// Prefer real data from the API (`explicitTubeType`). Only fall back to
  /// inferring from sample type when the backend hasn't sent tube type yet —
  /// this inference is a best-guess default, not authoritative.
  static TubeTypeInfo resolve({
    String? explicitTubeType,
    required String sampleType,
  }) {
    if (explicitTubeType != null && explicitTubeType.trim().isNotEmpty) {
      return TubeTypeInfo(explicitTubeType, _colorForLabel(explicitTubeType));
    }
    return forSampleType(sampleType);
  }

  /// Standard phlebotomy tube color-coding, keyed by common sample-type
  /// strings. Extend this map to match your lab's actual naming.
  static TubeTypeInfo forSampleType(String sampleType) {
    final key = sampleType.trim().toLowerCase();

    if (key.contains('edta'))
      return const TubeTypeInfo('EDTA (Lavender)', Color(0xFF8B7FD1));
    if (key.contains('serum') || key.contains('sst'))
      return const TubeTypeInfo('Serum (Gold/Red)', Color(0xFFD4A017));
    if (key.contains('citrate') ||
        key.contains('coag') ||
        key.contains('pt/inr'))
      return const TubeTypeInfo('Citrate (Light Blue)', Color(0xFF5B9BD5));
    if (key.contains('fluoride') || key.contains('glucose'))
      return const TubeTypeInfo('Fluoride (Grey)', Color(0xFF9AA0A6));
    if (key.contains('heparin'))
      return const TubeTypeInfo('Heparin (Green)', Color(0xFF4CAF50));
    if (key.contains('esr'))
      return const TubeTypeInfo('ESR (Black)', Color(0xFF3A3A3C));
    if (key.contains('urine'))
      return const TubeTypeInfo('Urine Container', Color(0xFFE8A33D));
    if (key.contains('stool'))
      return const TubeTypeInfo('Stool Container', Color(0xFF8D6E63));
    if (key.contains('swab'))
      return const TubeTypeInfo('Swab Kit', Color(0xFF7E57C2));
    if (key.contains('blood') || key.contains('tests'))
      return const TubeTypeInfo('EDTA (Lavender)', Color(0xFF8B7FD1));

    return const TubeTypeInfo('N/A', Color(0xFF9AA0A6));
  }

  static Color _colorForLabel(String label) {
    final key = label.toLowerCase();
    if (key.contains('lavender') || key.contains('edta')) {
      return const Color(0xFF8B7FD1);
    }
    if (key.contains('gold') || key.contains('red') || key.contains('serum')) {
      return const Color(0xFFD4A017);
    }
    if (key.contains('blue') || key.contains('citrate')) {
      return const Color(0xFF5B9BD5);
    }
    if (key.contains('grey') ||
        key.contains('gray') ||
        key.contains('fluoride')) {
      return const Color(0xFF9AA0A6);
    }
    if (key.contains('green') || key.contains('heparin')) {
      return const Color(0xFF4CAF50);
    }
    if (key.contains('black') || key.contains('esr')) {
      return const Color(0xFF3A3A3C);
    }
    if (key.contains('urine')) return const Color(0xFFE8A33D);
    if (key.contains('stool')) return const Color(0xFF8D6E63);
    if (key.contains('swab')) return const Color(0xFF7E57C2);
    return const Color(0xFF6B6B70);
  }
}

class SummaryTestItem {
  final String name;
  final String? code;

  /// Real tube type from the backend, when available. Null falls back to
  /// TubeTypeInfo.forSampleType() inference at render time.
  final String? tubeType;

  const SummaryTestItem(this.name, [this.code, this.tubeType]);

  const SummaryTestItem.withTube(this.name, {this.code, this.tubeType});
}

/*class OrderPatientSummaryCard extends StatefulWidget {
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
/// One sample-type group (e.g. "Blood • 5 ml") with its tests.
class SummarySampleGroup {
  final String sampleType;
  final String volume;
  final List<SummaryTestItem> tests;

  const SummarySampleGroup({
    required this.sampleType,
    this.volume = '',
    required this.tests,
  });
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


class SummaryTestItem {
  final String name;
  final String? code;

  const SummaryTestItem(this.name, [this.code]);
}*/
