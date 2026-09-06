import 'package:flutter/material.dart';
import 'package:lifenity_connect/features/team_lead/sample_live_tracking/view/widgets/tracking_bag_details.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_theme.dart';
import '../../controller/live_tracking_controller.dart';
import '../../model/bag_model.dart';
import '../../model/facility_model.dart' show FacilityUrgency, FacilityUrgencyX;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lifenity_connect/features/team_lead/sample_live_tracking/view/widgets/tracking_bag_details.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_theme.dart';
import '../../controller/live_tracking_controller.dart';
import '../../model/bag_model.dart';
import '../../model/facility_model.dart' show FacilityUrgency, FacilityUrgencyX;

class BagCard extends StatelessWidget {
  final BagModel bag;
  final LiveTrackingController controller;

  const BagCard({super.key, required this.bag, required this.controller});

  bool _hasValue(String? v) => v != null && v.trim().isNotEmpty;

  Color _darken(Color color, [double amount = .14]) {
    final hsl = HSLColor.fromColor(color);
    final darkened = hsl.withLightness(
      (hsl.lightness - amount).clamp(0.0, 1.0),
    );
    return darkened.toColor();
  }

  @override
  Widget build(BuildContext context) {
    final urgency = bag.urgency;
    final hasContact =
        _hasValue(bag.contactPersonName) || _hasValue(bag.contactPersonPhone);
    final hasTubes = (bag.tubecount ?? 0) > 0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _openDrilldown(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          /*boxShadow: [
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
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            margin: const EdgeInsets.only(top: 1),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.qr_code_2_rounded,
                              size: 19,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BAG CODE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                    color: Colors.white.withOpacity(0.75),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  bag.bagcode,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.body.copyWith(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    height: 1.15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _StatusBadge(label: bag.displayStatus),
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
                    Transform.translate(
                      offset: const Offset(0, -16),
                      child: _TatBanner(bag: bag),
                    ),
                    const SizedBox(height: 2),

                    // Info panel (contact / tubes) grouped w/ dividers
                    if (hasContact || hasTubes)
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
                            if (hasContact)
                              _InfoRow(
                                avatarColor: AppColors.purpleLight,
                                avatarIcon: Icons.person_outline_rounded,
                                avatarIconColor: AppColors.purpleText,
                                label: null,
                                name: bag.contactPersonName ?? '',
                                phone: bag.contactPersonPhone ?? '',
                              ),
                            if (hasContact && hasTubes)
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
                                name: '${bag.tubecount} tube(s) collected',
                                phone: '',
                              ),
                          ],
                        ),
                      ),

                    // Call button
                    if (_hasValue(bag.contactPersonPhone)) ...[
                      const SizedBox(height: 12),
                      _CallButton(phone: bag.contactPersonPhone),
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
    // Bags from the type-4 list have no facility code — pass 0, as the
    // drill-down endpoint expects for this case.
    controller.openBagDetail(bag);
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
            Icons.local_shipping_rounded,
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
  final BagModel bag;

  const _TatBanner({required this.bag});

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
    final bag = widget.bag;
    final elapsed = bag.tatTimeInHrs ?? bag.liveElapsedHours;
    final std = bag.stdTatTime;
    final urgency = bag.urgency;
    final isLive = elapsed != null && bag.tatTimeInHrs == null;

    final String text;
    if (elapsed == null) {
      text = 'Std TAT: ${std.toStringAsFixed(1)} hrs';
    } else if (bag.tatTimeInHrs != null) {
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
  final String? phone;

  const _CallButton({this.phone});

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
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.primary100,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.primary200, width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.phone_outlined,
                size: 13,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Call Contact',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/*
class BagCard extends StatelessWidget {
  final BagModel bag;
  final LiveTrackingController controller;

  const BagCard({super.key, required this.bag, required this.controller});

  bool _hasValue(String? v) => v != null && v.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final urgency = bag.urgency;
    final hasContact = _hasValue(bag.contactPersonName) || _hasValue(bag.contactPersonPhone);

    return GestureDetector(
      onTap: () => _openDrilldown(context),
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
                width: 4,
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
                      // ── Header: bag code + status ─────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.qr_code_2_rounded, size: 16, color: AppColors.textTertiary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    bag.bagcode,
                                    style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _StatusBadge(label: bag.displayStatus, urgency: urgency),
                        ],
                      ),

                      // ── TAT row ────────────────────────────
                      const SizedBox(height: 8),
                      _TatRow(bag: bag),

                      // ── Contact person row ─────────────────
                      if (hasContact) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(color: AppColors.purpleLight, shape: BoxShape.circle),
                              child: const Icon(Icons.person_outline_rounded, size: 13, color: AppColors.purpleText),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: AppTextStyles.bodySecondary,
                                  children: [
                                    TextSpan(
                                      text: bag.contactPersonName ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                    ),
                                    if (_hasValue(bag.contactPersonPhone))
                                      TextSpan(text: ' · ${bag.contactPersonPhone}'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // ── Tube count ─────────────────────────
                      if ((bag.tubecount ?? 0) > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.science_outlined, size: 14, color: AppColors.textTertiary),
                            const SizedBox(width: 5),
                            Text('${bag.tubecount} tube(s)', style: AppTextStyles.caption),
                          ],
                        ),
                      ],

                      // ── Call button ─────────────────────────
                      if (_hasValue(bag.contactPersonPhone)) ...[
                        const SizedBox(height: 12),
                        _CallButton(phone: bag.contactPersonPhone),
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
    // Bags from the type-4 list have no facility code — pass 0, as the
    // drill-down endpoint expects for this case.
    controller.openBagDetail(bag);
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
      decoration: BoxDecoration(color: urgency.bgColor, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: urgency.color)),
    );
  }
}

class _TatRow extends StatelessWidget {
  final BagModel bag;

  const _TatRow({required this.bag});

  @override
  Widget build(BuildContext context) {
    final elapsed = bag.tatTimeInHrs ?? bag.liveElapsedHours;
    final std = bag.stdTatTime;
    final urgency = bag.urgency;

    final String text;
    if (elapsed == null) {
      text = 'Std TAT: ${std.toStringAsFixed(1)} hrs';
    } else if (bag.tatTimeInHrs != null) {
      text = 'Completed in ${elapsed.toStringAsFixed(1)} hrs · Std ${std.toStringAsFixed(1)} hrs';
    } else {
      text = 'Elapsed ${elapsed.toStringAsFixed(1)} hrs · Std ${std.toStringAsFixed(1)} hrs';
    }

    return Row(
      children: [
        Icon(Icons.timer_outlined, size: 13, color: urgency.color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(color: urgency.color, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _CallButton extends StatelessWidget {
  final String? phone;

  const _CallButton({this.phone});

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
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.primary100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary200, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.phone_outlined, size: 14, color: AppColors.primary),
            SizedBox(width: 5),
            Text('Call Contact', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}*/
