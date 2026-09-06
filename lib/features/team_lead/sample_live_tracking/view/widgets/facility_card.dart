import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lifenity_connect/features/team_lead/sample_live_tracking/view/widgets/tracking_bag_details.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_theme.dart';
import '../../model/facility_model.dart';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_theme.dart';
import '../../controller/live_tracking_controller.dart';
import '../../model/facility_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lifenity_connect/features/team_lead/sample_live_tracking/view/widgets/tracking_bag_details.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_theme.dart';
import '../../controller/live_tracking_controller.dart';
import '../../model/facility_model.dart';

class FacilityCard extends StatelessWidget {
  final FacilityModel facility;
  final LiveTrackingController controller;

  const FacilityCard({
    super.key,
    required this.facility,
    required this.controller,
  });

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

  Color _darken(Color color, [double amount = .14]) {
    final hsl = HSLColor.fromColor(color);
    final darkened = hsl.withLightness(
      (hsl.lightness - amount).clamp(0.0, 1.0),
    );
    return darkened.toColor();
  }

  @override
  Widget build(BuildContext context) {
    final hasRbInfo = _hasValue(facility.rbName) || _hasValue(facility.rbPhone);
    final hasPhleboInfo =
        _hasValue(facility.phleboName) || _hasValue(facility.phleboPhone);
    final hasRbPhone = _hasValue(facility.rbPhone);
    final hasPhleboPhone = _hasValue(facility.phleboPhone);
    final hasTubes = (facility.tubecount ?? 0) > 0;
    final urgency = facility.urgency;

    // NOTE: assumes FacilityModel exposes `bagCode`. Rename below if your
    // model uses a different field (e.g. bagId / bagNumber).
    final hasBagCode = _hasValue(facility.bagcode);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _openDrilldown(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
        /*  boxShadow: [
            BoxShadow(
              color: urgency.color.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],*/
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Gradient header ─────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 16, 22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [urgency.color, _darken(urgency.color)],
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            facility.facilityName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body.copyWith(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${facility.ward} · ${facility.fType}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                          if (hasBagCode) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.qr_code_2_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Bag ${facility.bagcode}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _StatusBadge(label: facility.displayStatus),
                  ],
                ),
              ),

              // ── Body ─────────────────────────────────────────
              Container(
                color: AppColors.bgCard,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Floating TAT banner overlapping the seam
                    if (facility.hasBag) ...[
                      Transform.translate(
                        offset: const Offset(0, -16),
                        child: _TatBanner(facility: facility),
                      ),
                      const SizedBox(height: 2),
                    ] else
                      const SizedBox(height: 14),

                    // Info panel (RB / Phlebo / tubes) grouped w/ dividers
                    if (hasRbInfo || hasPhleboInfo || hasTubes)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.border,
                            width: 0.6,
                          ),
                        ),
                        child: Column(
                          children: [
                            if (hasRbInfo)
                              _InfoRow(
                                avatarColor: AppColors.purpleLight,
                                avatarIcon: Icons.person_outline_rounded,
                                avatarIconColor: AppColors.purpleText,
                                label: 'RB',
                                name: facility.rbName ?? '',
                                phone: facility.rbPhone ?? '',
                              ),
                            if (hasRbInfo && (hasPhleboInfo || hasTubes))
                              const Divider(
                                height: 1,
                                thickness: 0.6,
                                indent: 14,
                                endIndent: 14,
                                color: AppColors.border,
                              ),
                            if (hasPhleboInfo)
                              _InfoRow(
                                avatarColor: AppColors.tealLight,
                                avatarIcon: Icons.medical_services_outlined,
                                avatarIconColor: AppColors.tealText,
                                label: 'Phlebo',
                                name: facility.phleboName ?? '',
                                phone: facility.phleboPhone ?? '',
                              ),
                            if (hasPhleboInfo && hasTubes)
                              const Divider(
                                height: 1,
                                thickness: 0.6,
                                indent: 14,
                                endIndent: 14,
                                color: AppColors.border,
                              ),
                            if (hasTubes)
                              _InfoRow(
                                avatarColor: AppColors.primary100,
                                avatarIcon: Icons.science_outlined,
                                avatarIconColor: AppColors.primary,
                                label: null,
                                name: '${facility.tubecount} tube(s) collected',
                                phone: '',
                              ),
                          ],
                        ),
                      ),

                    // Call buttons
                    if (hasRbPhone || hasPhleboPhone) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (hasRbPhone)
                            Expanded(
                              child: _CallButton(
                                label: 'Call RB',
                                icon: Icons.phone_outlined,
                                bg: AppColors.primary100,
                                fg: AppColors.primary,
                                border: AppColors.primary200,
                                phone: facility.rbPhone,
                              ),
                            ),
                          if (hasRbPhone && hasPhleboPhone)
                            const SizedBox(width: 10),
                          if (hasPhleboPhone)
                            Expanded(
                              child: _CallButton(
                                label: 'Call Phlebo',
                                icon: Icons.medical_services_outlined,
                                bg: AppColors.secondary100,
                                fg: AppColors.secondary,
                                border: AppColors.secondary100,
                                phone: facility.phleboPhone,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDrilldown(BuildContext context) {
    controller.openFacilityDetail(facility);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BagDrilldownSheet(controller: controller),
    );
  }
}

// ── Subwidgets ───────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;

  const _StatusBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on_rounded,
            size: 13,
            color: AppColors.textPrimary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TatBanner extends StatefulWidget {
  final FacilityModel facility;

  const _TatBanner({required this.facility});

  @override
  State<_TatBanner> createState() => _TatBannerState();
}

class _TatBannerState extends State<_TatBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final facility = widget.facility;
    final elapsed = facility.tatTimeInHrs ?? facility.liveElapsedHours;
    final std = facility.stdTatTime;
    final urgency = facility.urgency;
    final isLive = elapsed != null && facility.tatTimeInHrs == null;

    final String text;
    if (elapsed == null) {
      text = 'Std TAT: ${std.toStringAsFixed(1)} hrs';
    } else if (facility.tatTimeInHrs != null) {
      text =
      'Completed in ${elapsed.toStringAsFixed(1)} hrs · Std ${std.toStringAsFixed(1)} hrs';
    } else {
      text =
      'Elapsed ${elapsed.toStringAsFixed(1)} hrs · Std ${std.toStringAsFixed(1)} hrs';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: urgency.color.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(
            color: urgency.color.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: urgency.bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.timer_outlined,
              size: 16,
              color: urgency.color,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: urgency.color,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ),
          if (isLive)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final scale = 0.85 + (_controller.value * 0.3);
                final opacity = 0.5 + (_controller.value * 0.5);
                return Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: urgency.color.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: urgency.color, width: 1.4),
                      ),
                      child: Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: urgency.color,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final Color avatarColor;
  final IconData avatarIcon;
  final Color avatarIconColor;
  final String? label;
  final String name;
  final String phone;

  const _InfoRow({
    required this.avatarColor,
    required this.avatarIcon,
    required this.avatarIconColor,
    required this.label,
    required this.name,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: avatarColor,
              shape: BoxShape.circle,
            ),
            child: Icon(avatarIcon, size: 14, color: avatarIconColor),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodySecondary,
                children: [
                  if (label != null)
                    TextSpan(
                      text: '$label: ',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  TextSpan(
                    text: name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (phone.trim().isNotEmpty)
                    TextSpan(
                      text: ' · $phone',
                      style: const TextStyle(color: AppColors.textSecondary),
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

class _CallButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  final Color border;
  final String? phone;

  const _CallButton({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.border,
    this.phone,
  });

  Future<void> _call() async {
    if (phone == null || phone!.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _call,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: border, width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
              child: Icon(icon, size: 13, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
/*
class FacilityCard extends StatelessWidget {
  final FacilityModel facility;
  final LiveTrackingController controller;

  const FacilityCard({
    super.key,
    required this.facility,
    required this.controller,
  });

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final hasRbInfo = _hasValue(facility.rbName) || _hasValue(facility.rbPhone);
    final hasPhleboInfo =
        _hasValue(facility.phleboName) || _hasValue(facility.phleboPhone);
    final hasRbPhone = _hasValue(facility.rbPhone);
    final hasPhleboPhone = _hasValue(facility.phleboPhone);
    final urgency = facility.urgency;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _openDrilldown(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Urgency strip ──────────────────────────────
              Container(
                width: 6,
                decoration: BoxDecoration(
                  color: urgency.color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header ─────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  facility.facilityName,
                                  style: AppTextStyles.body.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${facility.ward} · ${facility.fType}',
                                  style: AppTextStyles.caption,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(
                            label: facility.displayStatus,
                            urgency: urgency,
                          ),
                        ],
                      ),

                      // ── TAT row ────────────────────────────
                      if (facility.hasBag) ...[
                        const SizedBox(height: 8),
                        _TatRow(facility: facility),
                      ],

                      // ── RB Row ──────────────────────────────
                      if (hasRbInfo) ...[
                        const SizedBox(height: 10),
                        _InfoRow(
                          avatarColor: AppColors.purpleLight,
                          avatarIcon: Icons.person_outline_rounded,
                          avatarIconColor: AppColors.purpleText,
                          label: 'RB:',
                          name: facility.rbName,
                          phone: facility.rbPhone ?? '',
                        ),
                      ],

                      // ── Phlebo Row ────────────────────────────
                      if (hasPhleboInfo) ...[
                        const SizedBox(height: 8),
                        _InfoRow(
                          avatarColor: AppColors.tealLight,
                          avatarIcon: Icons.medical_services_outlined,
                          avatarIconColor: AppColors.tealText,
                          label: 'Phlebo:',
                          name: facility.phleboName ?? '',
                          phone: facility.phleboPhone ?? '',
                        ),
                      ],

                      // ── Tube count ─────────────────────────────
                      if ((facility.tubecount ?? 0) > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.science_outlined,
                              size: 14,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${facility.tubecount} tube(s) collected',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                      ],

                      // ── Call Buttons ────────────────────────────
                      if (hasRbPhone || hasPhleboPhone) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (hasRbPhone)
                              Expanded(
                                child: _CallButton(
                                  label: 'Call RB',
                                  icon: Icons.phone_outlined,
                                  bg: AppColors.primary100,
                                  fg: AppColors.primary,
                                  border: AppColors.primary200,
                                  phone: facility.rbPhone,
                                ),
                              ),
                            if (hasRbPhone && hasPhleboPhone)
                              const SizedBox(width: 8),
                            if (hasPhleboPhone)
                              Expanded(
                                child: _CallButton(
                                  label: 'Call Phlebo',
                                  icon: Icons.medical_services_outlined,
                                  bg: AppColors.tealLight,
                                  fg: AppColors.tealText,
                                  border: AppColors.tealBorder,
                                  phone: facility.phleboPhone,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDrilldown(BuildContext context) {
    controller.openFacilityDetail(facility);
    showModalBottomSheet(

      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BagDrilldownSheet(controller: controller),
    );
  }
}

// ── Subwidgets ───────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String label;
  final FacilityUrgency urgency;

  const _StatusBadge({required this.label, required this.urgency});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: urgency.bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: urgency.color,
        ),
      ),
    );
  }
}

class _TatRow extends StatelessWidget {
  final FacilityModel facility;

  const _TatRow({required this.facility});

  @override
  Widget build(BuildContext context) {
    final elapsed = facility.tatTimeInHrs ?? facility.liveElapsedHours;
    final std = facility.stdTatTime;
    final urgency = facility.urgency;

    final String text;
    if (elapsed == null) {
      text = 'Std TAT: ${std.toStringAsFixed(1)} hrs';
    } else if (facility.tatTimeInHrs != null) {
      text =
          'Completed in ${elapsed.toStringAsFixed(1)} hrs · Std ${std.toStringAsFixed(1)} hrs';
    } else {
      text =
          'Elapsed ${elapsed.toStringAsFixed(1)} hrs · Std ${std.toStringAsFixed(1)} hrs';
    }

    return Row(
      children: [
        Icon(Icons.timer_outlined, size: 13, color: urgency.color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(
              color: urgency.color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final Color avatarColor;
  final IconData avatarIcon;
  final Color avatarIconColor;
  final String label;
  final String name;
  final String phone;

  const _InfoRow({
    required this.avatarColor,
    required this.avatarIcon,
    required this.avatarIconColor,
    required this.label,
    required this.name,
    required this.phone,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: avatarColor, shape: BoxShape.circle),
          child: Icon(avatarIcon, size: 13, color: avatarIconColor),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: AppTextStyles.bodySecondary,
              children: [
                TextSpan(
                  text: '$label ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                TextSpan(
                  text: name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (phone.trim().isNotEmpty) TextSpan(text: ' · $phone'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CallButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bg;
  final Color fg;
  final Color border;
  final String? phone;

  const _CallButton({
    required this.label,
    required this.icon,
    required this.bg,
    required this.fg,
    required this.border,
    this.phone,
  });

  Future<void> _call() async {
    if (phone == null || phone!.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _call,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/
