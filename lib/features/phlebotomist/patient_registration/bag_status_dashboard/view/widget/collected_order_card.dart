import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../../../theme/app_colors.dart';
import '../../model/active_bag_model.dart';
import 'dart:ui' as ui;



/// One collected order (one patient) inside a QR bag, rendered as a
/// compact, tappable card. Tapping opens [CollectedOrderDetailSheet] with
/// the full, untruncated breakdown of tests, tubes, and barcodes.
///
/// Use this in place of any local `_PatientCard` — it's meant to be the
/// single shared implementation for both the standalone
/// `CollectedOrdersList` screen and `BagDetailView`'s "Collected Orders" tab.
class CollectedOrderCard extends StatefulWidget {
  final PatientOrder order;

  const CollectedOrderCard({super.key, required this.order});

  @override
  State<CollectedOrderCard> createState() => _CollectedOrderCardState();
}

class _CollectedOrderCardState extends State<CollectedOrderCard> {
  bool _pressed = false;

  void _openDetails() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CollectedOrderDetailSheet(order: widget.order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final reg = order.registration;
    final hasName = order.hasPatientName;
    final isHomeVisit = reg.visitType.toLowerCase().contains('home');

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: _openDetails,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Ribbon(isHomeVisit: isHomeVisit),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _IdentityRow(order: order, hasName: hasName),
                    if (reg.clinicName.isNotEmpty || reg.address.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _AddressRow(reg: reg),
                    ],
                    if (order.barcodes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _BarcodeRow(barcodes: order.barcodes, onViewAll: _openDetails),
                    ],
                    const SizedBox(height: 10),
                    _TestsAndTubesSummary(order: order, onTapDetails: _openDetails),
                    const SizedBox(height: 10),
                    _CollectedMetaRow(reg: reg),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Ribbon: visit type + a quiet "Collected" badge ───────────────────────

class _Ribbon extends StatelessWidget {
  final bool isHomeVisit;
  const _Ribbon({required this.isHomeVisit});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgCardAlt,
      padding: const EdgeInsets.only(right: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              bottomRight: Radius.circular(14),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: isHomeVisit ? AppColors.tealText : AppColors.purple,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isHomeVisit ? Icons.home_outlined : Icons.local_hospital_outlined,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isHomeVisit ? 'Home Collection' : 'Clinic Collection',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.grayLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, size: 13, color: AppColors.tealText),
                  SizedBox(width: 4),
                  Text(
                    'Collected',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.tealText),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Identity: avatar, name, age/order id ─────────────────────────────────

class _IdentityRow extends StatelessWidget {
  final PatientOrder order;
  final bool hasName;
  const _IdentityRow({required this.order, required this.hasName});

  static const _unknownColor = Color(0xFFFC8181);

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final reg = order.registration;
    final name = hasName ? reg.patientName.trim() : 'Unidentified Patient';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: hasName ? AppColors.primary100 : _unknownColor.withOpacity(0.15),
          child: Text(
            _initials(name),
            style: TextStyle(
              color: hasName ? AppColors.primary800 : _unknownColor,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: hasName ? AppColors.textPrimary : _unknownColor,
                      ),
                    ),
                  ),
                  if (!hasName)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _unknownColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Unknown',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _unknownColor),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                [
                  if (reg.age.isNotEmpty) 'Age: ${reg.age}',
                  'ID: ORD${reg.sampleCollectionOrderID}',
                ].join('  ·  '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Address ───────────────────────────────────────────────────────────────

class _AddressRow extends StatelessWidget {
  final RegistrationDetails reg;
  const _AddressRow({required this.reg});

  @override
  Widget build(BuildContext context) {
    final text = [reg.clinicName, reg.address].where((s) => s.isNotEmpty).join(', ');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textQuaternary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

// ─── Barcodes: real chips, not a single "primary + more" line ─────────────

class _BarcodeRow extends StatelessWidget {
  final List<BarcodeDetail> barcodes;
  final VoidCallback onViewAll;
  const _BarcodeRow({required this.barcodes, required this.onViewAll});

  static const int _maxShown = 3;

  @override
  Widget build(BuildContext context) {
    final shown = barcodes.take(_maxShown).toList();
    final remaining = barcodes.length - shown.length;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final b in shown) _BarcodeChip(code: b.barcodeNo),
        if (remaining > 0)
          GestureDetector(
            onTap: onViewAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+$remaining more',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary800),
              ),
            ),
          ),
      ],
    );
  }
}

class _BarcodeChip extends StatelessWidget {
  final String code;
  const _BarcodeChip({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF4299E1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF4299E1).withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.qr_code_2_rounded, size: 13, color: Color(0xFF4299E1)),
          const SizedBox(width: 4),
          Text(
            code,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2B6CB0),
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tests & tubes: PatientCard-style rows, or a tap-to-view hint if they'd wrap ─

class _TestsAndTubesSummary extends StatelessWidget {
  final PatientOrder order;
  final VoidCallback onTapDetails;
  const _TestsAndTubesSummary({required this.order, required this.onTapDetails});

  static const _rowStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    height: 1.3,
  );

  bool _overflowsOneLine(String text, TextStyle style, double maxWidth) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    return painter.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    final testsText = order.testNamesJoined;
    final tubesText = order.tubesSummary;

    if (testsText.isEmpty && tubesText.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        // subtract icon + horizontal padding used inside each row (~44px)
        final innerWidth = constraints.maxWidth - 44;

        final testsOverflow = testsText.isNotEmpty && _overflowsOneLine(testsText, _rowStyle, innerWidth);
        final tubesOverflow = tubesText.isNotEmpty && _overflowsOneLine(tubesText, _rowStyle, innerWidth);

        if (testsOverflow || tubesOverflow) {
          return GestureDetector(
            onTap: onTapDetails,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.grayLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.science_outlined, size: 15, color: AppColors.textTertiary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${order.tests.length} test${order.tests.length == 1 ? '' : 's'} · tap to view details',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.textQuaternary),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (testsText.isNotEmpty)
              _row(Icons.science_outlined, AppColors.redText, AppColors.redLight, testsText),
            if (testsText.isNotEmpty && tubesText.isNotEmpty) const SizedBox(height: 8),
            if (tubesText.isNotEmpty)
              _row(Icons.vaccines_outlined, AppColors.purpleText, AppColors.purpleLight, tubesText),
          ],
        );
      },
    );
  }

  Widget _row(IconData icon, Color iconColor, Color bg, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: bg.withOpacity(0.4), borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 6),
          Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: _rowStyle)),
        ],
      ),
    );
  }
}

// ─── Collected date/time — the actual field from the response, not a slot ──

class _CollectedMetaRow extends StatelessWidget {
  final RegistrationDetails reg;
  const _CollectedMetaRow({required this.reg});

  String get _formatted {
    final dt = reg.collectionDateTime;
    if (dt == null) return 'Not recorded';
    return DateFormat('dd MMM yyyy · hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(color: AppColors.grayLight, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, size: 16, color: AppColors.tealText),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Collected On',
                  style: TextStyle(fontSize: 10.5, color: AppColors.textQuaternary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatted,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Detail sheet: full, untruncated view ─────────────────────────────────

class CollectedOrderDetailSheet extends StatelessWidget {
  final PatientOrder order;
  const CollectedOrderDetailSheet({super.key, required this.order});

  String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  Map<String, int> _tubeCounts() {
    final counts = <String, int>{};
    for (final t in order.tests) {
      if (t.tubeContent.isEmpty) continue;
      counts[t.tubeContent] = (counts[t.tubeContent] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final reg = order.registration;
    final hasName = order.hasPatientName;

    return DraggableScrollableSheet(
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
              const SizedBox(height: 10),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor:
                          hasName ? AppColors.primary100 : const Color(0xFFFC8181).withOpacity(0.15),
                          child: Text(
                            _initials(hasName ? reg.patientName : '?'),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: hasName ? AppColors.primary800 : const Color(0xFFFC8181),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasName ? reg.patientName.trim() : 'Unidentified Patient',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [
                                  if (reg.age.isNotEmpty) 'Age: ${reg.age}',
                                  if (reg.gender.isNotEmpty) reg.gender,
                                  'ID: ORD${reg.sampleCollectionOrderID}',
                                ].join('  ·  '),
                                style: const TextStyle(fontSize: 12.5, color: AppColors.textTertiary, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const _SectionLabel('Collection'),
                    const SizedBox(height: 8),
                    _InfoTile(
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: AppColors.tealText,
                      label: 'Collected on',
                      value: reg.collectionDateTime != null
                          ? DateFormat('dd MMM yyyy · hh:mm a').format(reg.collectionDateTime!)
                          : 'Not recorded',
                    ),
                    const SizedBox(height: 8),
                    _InfoTile(
                      icon: reg.visitType.toLowerCase().contains('home')
                          ? Icons.home_outlined
                          : Icons.local_hospital_outlined,
                      iconColor: AppColors.purple,
                      label: 'Visit type',
                      value: reg.visitType.isNotEmpty ? reg.visitType : '—',
                    ),
                    if (reg.mobileNumber.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _InfoTile(
                        icon: Icons.call_outlined,
                        iconColor: AppColors.tealText,
                        label: 'Mobile',
                        value: reg.mobileNumber,
                      ),
                    ],
                    if (reg.clinicName.isNotEmpty || reg.address.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _InfoTile(
                        icon: Icons.location_on_outlined,
                        iconColor: AppColors.blue,
                        label: 'Location',
                        value: [reg.clinicName, reg.address].where((s) => s.isNotEmpty).join(', '),
                      ),
                    ],

                    if (order.barcodes.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      _SectionLabel('Barcodes (${order.barcodes.length})'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: order.barcodes.map((b) => _BarcodeChip(code: b.barcodeNo)).toList(),
                      ),
                    ],

                    if (order.tests.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      _SectionLabel('Tests (${order.tests.length})'),
                      const SizedBox(height: 8),
                      ...order.tests.map(
                            (t) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _InfoTile(
                            icon: Icons.science_outlined,
                            iconColor: AppColors.redText,
                            label: t.sampleTypeName.isNotEmpty ? t.sampleTypeName : 'Sample',
                            value: t.testName,
                          ),
                        ),
                      ),
                    ],

                    if (_tubeCounts().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const _SectionLabel('Tubes'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                        _tubeCounts().entries.map((e) => _TubePill(label: e.key, count: e.value)).toList(),
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
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        color: AppColors.textQuaternary,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _InfoTile({required this.icon, required this.iconColor, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: AppColors.grayLight, borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textQuaternary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TubePill extends StatelessWidget {
  final String label;
  final int count;
  const _TubePill({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.purpleLight.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.vaccines_outlined, size: 14, color: AppColors.purpleText),
          const SizedBox(width: 6),
          Text('$count× $label', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.purpleText)),
        ],
      ),
    );
  }
}