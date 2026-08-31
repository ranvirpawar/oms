// ─────────────────────────────────────────────────────────────────────────────
// facility_card.dart
//
// The main card shown on the Consumption Dashboard.
// Shows one facility type with its category breakdown (Basic A, Basic B, Advance).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../model/consumption_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FacilityCard — redesigned with Target / Actual / Difference as hero data
// ─────────────────────────────────────────────────────────────────────────────

class FacilityCard extends StatefulWidget {
  final String facilityName;
  final List<ConsumptionModel> categories; // up to 3 items
  final VoidCallback? onTap;

  const FacilityCard({
    super.key,
    required this.facilityName,
    required this.categories,
    this.onTap,
  });

  @override
  State<FacilityCard> createState() => _FacilityCardState();
}

class _FacilityCardState extends State<FacilityCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // ── Aggregates ────────────────────────────────────────────────────────────
  int get _totalActual  => widget.categories.fold(0, (s, e) => s + e.patCount);
  int get _totalTarget  => widget.categories.fold(0, (s, e) => s + e.yearlyTarget);
  int get _totalDiff    => _totalActual - _totalTarget;
  double get _overallPct =>
      _totalTarget > 0 ? (_totalActual / _totalTarget * 100).clamp(0, 200) : 0;

  // ── Category colours ──────────────────────────────────────────────────────
  static const _catColors = [
    Color(0xFF4F46E5), // indigo
    Color(0xFF0EA5E9), // sky
    Color(0xFF10B981), // emerald
  ];

  Color _colorFor(int i) => _catColors[i.clamp(0, _catColors.length - 1)];

  // ── Zone-aware fill colour for progress bar ───────────────────────────────
  Color _barColor(double ratio) {
    if (ratio >= 1.0)  return const Color(0xFF22C55E); // green  — exceeded
    if (ratio >= 0.75) return const Color(0xFFF59E0B); // amber  — close
    if (ratio >= 0.50) return const Color(0xFFF97316); // orange — mid
    return const Color(0xFFEF4444);                    // red    — low
  }

  // ── Number formatting ─────────────────────────────────────────────────────
  String _fmt(int n) {
    final a = n.abs();
    if (a >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (a >= 1000)    return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  // ── Badge styling based on overall % ─────────────────────────────────────
  ({Color bg, Color fg}) _badgeStyle(double pct) {
    if (pct >= 100) return (bg: const Color(0xFFDCFCE7), fg: const Color(0xFF16A34A));
    if (pct >= 50)  return (bg: const Color(0xFFFEF3C7), fg: const Color(0xFFB45309));
    return           (bg: const Color(0xFFFFE4E6), fg: const Color(0xFFBE123C));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            _buildKpiStrip(),
            _buildDivider(),
            _buildCategories(),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final badge = _badgeStyle(_overallPct);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Row(
        children: [
          // Icon
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_hospital_rounded,
                color: Color(0xFF3B82F6), size: 18),
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.facilityName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.categories.length} programme categories',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Overall % badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badge.bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${_overallPct.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: badge.fg,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── KPI strip — Target · Actual · Difference ──────────────────────────────
  Widget _buildKpiStrip() {
    final exceeded = _totalDiff >= 0;
    final diffColor = exceeded
        ? const Color(0xFF16A34A)
        : const Color(0xFFBE123C);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        border: Border.symmetric(
          horizontal: BorderSide(color: Color(0xFFE5E7EB), width: 0.8),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            _kpiCell(
              label: 'YEARLY TARGET',
              value: _fmt(_totalTarget),
              valueColor: const Color(0xFF111827),
              sub: 'annual goal',
            ),
            _verticalDivider(),
            _kpiCell(
              label: 'ACTUAL',
              value: _fmt(_totalActual),
              valueColor: const Color(0xFF111827),
              sub: 'patients served',
            ),
            _verticalDivider(),
            _kpiCell(
              label: 'DIFFERENCE',
              value: '${exceeded ? "+" : ""}${_fmt(_totalDiff)}',
              valueColor: diffColor,
              sub: exceeded ? 'target exceeded' : 'to reach goal',
              subColor: diffColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _kpiCell({
    required String label,
    required String value,
    required Color valueColor,
    required String sub,
    Color? subColor,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.7,
                  color: Color(0xFF9CA3AF),
                )),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: valueColor,
                  height: 1,
                )),
            const SizedBox(height: 3),
            Text(sub,
                style: TextStyle(
                  fontSize: 10,
                  color: subColor ?? const Color(0xFF9CA3AF),
                )),
          ],
        ),
      ),
    );
  }

  Widget _verticalDivider() => const VerticalDivider(
    width: 0.8,
    thickness: 0.8,
    color: Color(0xFFE5E7EB),
  );

  Widget _buildDivider() => const Divider(height: 0.8, thickness: 0.8,
      color: Color(0xFFE5E7EB));

  // ── Category rows ─────────────────────────────────────────────────────────
  Widget _buildCategories() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        children: [
          for (int i = 0; i < widget.categories.length; i++) ...[
            if (i > 0) ...[
              const SizedBox(height: 4),
              const Divider(height: 16, thickness: 0.6, color: Color(0xFFF3F4F6)),
            ],
            _buildCategoryRow(widget.categories[i], i),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryRow(ConsumptionModel item, int index) {
    final catColor = _colorFor(index);
    final ratio    = item.yearlyTarget > 0
        ? (item.patCount / item.yearlyTarget).clamp(0.0, 1.0)
        : 0.0;
    final diff     = item.patCount - item.yearlyTarget;
    final exceeded = diff >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Meta row ──────────────────────────────────────────────────────
        Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: catColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(item.catName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                  )),
            ),
            // Actual / Target
            RichText(
              text: TextSpan(children: [
                TextSpan(
                  text: _fmt(item.patCount),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: catColor,
                  ),
                ),
                TextSpan(
                  text: ' / ${_fmt(item.yearlyTarget)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            // Diff pill
            _diffPill(diff, exceeded),
          ],
        ),

        const SizedBox(height: 10),

        // ── Range bar with zone ticks ─────────────────────────────────────
        _buildRangeBar(ratio),

        const SizedBox(height: 5),

        // ── Zone tick labels ──────────────────────────────────────────────
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ZoneLabel('0'),
            _ZoneLabel('25%'),
            _ZoneLabel('50%'),
            _ZoneLabel('75%'),
            _ZoneLabel('100%'),
          ],
        ),
      ],
    );
  }

  Widget _diffPill(int diff, bool exceeded) {
    final label = exceeded
        ? '+${_fmt(diff)} exceeded'
        : '${_fmt(diff.abs())} remaining';
    final Color bg, fg;
    if (exceeded) {
      bg = const Color(0xFFDCFCE7); fg = const Color(0xFF16A34A);
    } else if ((diff.abs() / (_totalTarget > 0 ? _totalTarget : 1)) < 0.25) {
      bg = const Color(0xFFFEF3C7); fg = const Color(0xFFB45309);
    } else {
      bg = const Color(0xFFFFE4E6); fg = const Color(0xFFBE123C);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: fg,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _buildRangeBar(double ratio) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final animated = CurvedAnimation(
          parent: _ctrl,
          curve: Curves.easeOutCubic,
        ).value;
        final fillW = ratio * animated;

        return LayoutBuilder(builder: (ctx, constraints) {
          final total = constraints.maxWidth;

          return ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: SizedBox(
              height: 10,
              child: Stack(
                children: [
                  // Track
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  // Fill
                  FractionallySizedBox(
                    widthFactor: fillW.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _barColor(ratio),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  // Zone tick marks at 25%, 50%, 75%
                  for (final zone in [0.25, 0.50, 0.75])
                    Positioned(
                      left: total * zone - 0.75,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 1.5,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tiny zone label widget
// ─────────────────────────────────────────────────────────────────────────────
class _ZoneLabel extends StatelessWidget {
  final String text;
  const _ZoneLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 9,
        color: Color(0xFFD1D5DB),
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}
/*class FacilityCard extends StatelessWidget {
  final String facilityName;
  final List<ConsumptionModel> categories; // up to 3 items (Basic A, B, Advance)
  final VoidCallback? onTap;

  const FacilityCard({
    super.key,
    required this.facilityName,
    required this.categories,
    this.onTap,
  });

  // ── Colors per category ──────────────────────────────────────────────────
  static const _categoryColors = [
    Color(0xFF6366F1), // Basic A — indigo
    Color(0xFF0EA5E9), // Basic B — sky blue
    Color(0xFF10B981), // Advance — emerald
  ];

  Color _colorFor(int mobCatCode) {
    final idx = (mobCatCode - 1).clamp(0, _categoryColors.length - 1);
    return _categoryColors[idx];
  }

  // ── Total patients across all categories ────────────────────────────────
  int get _totalPatients => categories.fold(0, (s, e) => s + e.patCount);
  int get _totalTarget => categories.fold(0, (s, e) => s + e.yearlyTarget);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card Header ─────────────────────────────────────────────
            _buildHeader(),
            // ── Category Rows ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  for (int i = 0; i < categories.length; i++) ...[
                    if (i > 0) const SizedBox(height: 14),
                    _buildCategoryRow(categories[i]),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Overall completion across all categories of this facility
    final overallPercent = _totalTarget > 0
        ? (_totalPatients / _totalTarget * 100).clamp(0, 100)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_hospital_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          // Facility name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  facilityName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$_totalPatients patients · ${overallPercent.toStringAsFixed(1)}% achieved',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          // Arrow hint (will navigate to detail screen later)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white70, size: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow(ConsumptionModel item) {
    final color = _colorFor(item.mobCatCode);
    final isOverTarget = item.diff < 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          children: [
            // Colour dot
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            // Category name
            Text(
              item.catName,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const Spacer(),
            // Patient count
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: _formatNumber(item.patCount),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  TextSpan(
                    text: ' / ${_formatNumber(item.yearlyTarget)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Percentage badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: isOverTarget
                    ? const Color(0xFF10B981).withOpacity(0.1)
                    : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${item.completionPercent.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isOverTarget ? const Color(0xFF10B981) : color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Animated bar
        AnimatedRangeBar(
          value: item.completionRatio,
          fillColor: color,
          height: 7,
          duration: const Duration(milliseconds: 1000),
        ),
        const SizedBox(height: 6),
        // Diff label
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              isOverTarget
                  ? Icons.check_circle_rounded
                  : Icons.arrow_upward_rounded,
              size: 11,
              color: isOverTarget
                  ? const Color(0xFF10B981)
                  : const Color(0xFF9CA3AF),
            ),
            const SizedBox(width: 3),
            Text(
              isOverTarget
                  ? 'Target exceeded'
                  : '${_formatNumber(item.diff)} remaining',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isOverTarget
                    ? const Color(0xFF10B981)
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatNumber(int n) {
    if (n.abs() >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n.abs() >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}*/
