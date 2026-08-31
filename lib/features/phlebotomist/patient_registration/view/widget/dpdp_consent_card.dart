import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../controller/patient_registration_controller.dart';


/// A standalone, reactive DPDP consent card.
///
/// ```dart
/// Obx(() {
///   if (!controller.showConsentSection.value) return const SizedBox.shrink();
///   return DpdpConsentCard(controller: controller);
/// })
/// ```
class DpdpConsentCard extends StatelessWidget {
  const DpdpConsentCard({super.key, required this.controller});

  final PatientRegistrationController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final Widget child;
      if (controller.isCheckingConsent.value) {
        child = const _CheckingState(key: ValueKey('checking'));
      } else if (controller.isConsentVerified.value) {
        child = _VerifiedState(
          key: const ValueKey('verified'),
          message: controller.consentStatusMessage.value,
        );
      } else if (controller.isConsentLinkSent.value) {
        child = _LinkSentState(
          key: const ValueKey('linkSent'),
          controller: controller,
        );
      } else {
        child = _InitialState(
          key: const ValueKey('initial'),
          controller: controller,
        );
      }

      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (widget, animation) => FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1,
            child: widget,
          ),
        ),
        child: child,
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Palette — refreshed away from stock Material blue/green/orange
// ─────────────────────────────────────────────────────────────────────────

class _Palette {
  // Indigo — "in progress / awaiting response"
  static const inProgress = Color(0xFF5B5FEF);
  static const inProgressDeep = Color(0xFF4448C9);
  // Emerald — "verified / success"
  static const success = Color(0xFF12B76A);
  static const successDeep = Color(0xFF0C9459);
  // Amber — "action needed"
  static const attention = Color(0xFFF59E0B);
  static const attentionDeep = Color(0xFFD97F06);
  // Rose — errors
  static const danger = Color(0xFFF04438);
}

// ─────────────────────────────────────────────────────────────────────────
// Shared building blocks
// ─────────────────────────────────────────────────────────────────────────

class _ConsentShell extends StatelessWidget {
  const _ConsentShell({required this.accent, required this.child});

  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withOpacity(0.10), accent.withOpacity(0.03)],
        ),
        border: Border.all(color: accent.withOpacity(0.22)),
        /*boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.10),
            blurRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],*/
      ),
      child: child,
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.color,
    this.size = 24,
    this.iconSize = 18,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withOpacity(0.14), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.16), borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.2),
      ),
    );
  }
}

class _ThinProgressBar extends StatelessWidget {
  const _ThinProgressBar({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 3,
        child: LinearProgressIndicator(
          backgroundColor: color.withOpacity(0.12),
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    );
  }
}

class _PulsingIconBadge extends StatefulWidget {
  const _PulsingIconBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  State<_PulsingIconBadge> createState() => _PulsingIconBadgeState();
}

class _PulsingIconBadgeState extends State<_PulsingIconBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Transform.scale(
          scale: 1.0 + (t * 0.08),
          child: Opacity(opacity: 0.75 + (t * 0.25), child: child),
        );
      },
      child: _IconBadge(icon: widget.icon, color: widget.color, size: 44, iconSize: 22),
    );
  }
}

/// Small "live" indicator — a solid dot with an expanding, fading ring
/// behind it, like a radar ping. Used next to any label that represents an
/// active background fetch/poll, so the user has a persistent, low-noise
/// cue that something is actually happening right now.
class _LiveDot extends StatefulWidget {
  const _LiveDot({required this.color, this.size = 8});

  final Color color;
  final double size;

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ringMax = widget.size * 3.2;
    return SizedBox(
      width: ringMax,
      height: ringMax,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1 - t).clamp(0.0, 1.0),
                child: Container(
                  width: widget.size + (ringMax - widget.size) * t,
                  height: widget.size + (ringMax - widget.size) * t,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color.withOpacity(0.35)),
                ),
              ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                  boxShadow: [BoxShadow(color: widget.color.withOpacity(0.6), blurRadius: 6)],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InlineBanner extends StatelessWidget {
  const _InlineBanner({required this.message, required this.color});

  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 15, color: color),
          const SizedBox(width: 6),
          Expanded(child: Text(message, style: TextStyle(color: color, fontSize: 12, height: 1.3))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Alive button — consistent elevation + real tap feedback
// ─────────────────────────────────────────────────────────────────────────

enum _ButtonVariant { primary, tonal, ghost }

/// A button that actually feels pressed: it scales down slightly on
/// tap-down and springs back on release, and carries a soft, color-tinted
/// shadow so every button in the card sits at the same visual "height"
/// instead of some being flat outlines and others filled.
class _AliveButton extends StatefulWidget {
  const _AliveButton({
    required this.label,
    required this.color,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.variant = _ButtonVariant.tonal,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final _ButtonVariant variant;

  @override
  State<_AliveButton> createState() => _AliveButtonState();
}

class _AliveButtonState extends State<_AliveButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  @override
  Widget build(BuildContext context) {
    final isPrimary = widget.variant == _ButtonVariant.primary;
    final isGhost = widget.variant == _ButtonVariant.ghost;

    final Color fg = isPrimary
        ? Colors.white
        : (_enabled ? widget.color : widget.color.withOpacity(0.4));

    BoxDecoration decoration;
    if (isGhost) {
      decoration = const BoxDecoration();
    } else if (isPrimary) {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _enabled
              ? [widget.color, Color.lerp(widget.color, Colors.black, 0.18)!]
              : [widget.color.withOpacity(0.35), widget.color.withOpacity(0.35)],
        ),
       /* boxShadow: _enabled
            ? [
          BoxShadow(
            color: widget.color.withOpacity(_pressed ? 0.18 : 0.38),
            blurRadius: _pressed ? 6 : 14,
            offset: Offset(0, _pressed ? 2 : 6),
          ),
        ]
            : null,*/
      );
    } else {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: _enabled ? widget.color.withOpacity(0.13) : widget.color.withOpacity(0.06),
        border: Border.all(color: widget.color.withOpacity(_enabled ? 0.28 : 0.12)),
        boxShadow: _enabled
            ? [
          BoxShadow(
            color: widget.color.withOpacity(_pressed ? 0.05 : 0.14),
            blurRadius: _pressed ? 4 : 10,
            offset: Offset(0, _pressed ? 1 : 4),
          ),
        ]
            : null,
      );
    }

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.loading)
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        else if (widget.icon != null)
          Icon(widget.icon, size: 16, color: fg),
        if (widget.loading || widget.icon != null) const SizedBox(width: 7),
        Flexible(
          child: Text(
            widget.label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: fg),
          ),
        ),
      ],
    );

    return GestureDetector(
      onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: () => setState(() => _pressed = false),
      onTap: _enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: isGhost
              ? const EdgeInsets.symmetric(vertical: 6)
              : const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: decoration,
          child: content,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// States
// ─────────────────────────────────────────────────────────────────────────

class _CheckingState extends StatelessWidget {
  const _CheckingState({super.key});

  static const _accent = _Palette.inProgress;

  @override
  Widget build(BuildContext context) {
    return _ConsentShell(
      accent: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _PulsingIconBadge(icon: Icons.hourglass_bottom_rounded, color: _accent),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Checking DPDP consent status',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const _LiveDot(color: _accent),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _ThinProgressBar(color: _accent),
        ],
      ),
    );
  }
}

class _VerifiedState extends StatelessWidget {
  const _VerifiedState({super.key, required this.message});

  final String message;

  static const _accent = _Palette.success;

  @override
  Widget build(BuildContext context) {
    return _ConsentShell(
      accent: _accent,
      child: Row(
        children: [
          const _IconBadge(icon: Icons.verified_rounded, color: _accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const _StatusPill(label: 'VERIFIED', color: _accent),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade800, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkSentState extends StatelessWidget {
  const _LinkSentState({super.key, required this.controller});

  final PatientRegistrationController controller;

  static const _accent = _Palette.inProgress;

  @override
  Widget build(BuildContext context) {
    return Obx(
          () => _ConsentShell(
        accent: _accent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _IconBadge(icon: Icons.mark_email_read_rounded, color: _accent, ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('DPDP consent link sent', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
                ),
                if (controller.isPollingConsent.value) ...[
                  const _LiveDot(color: _accent),
                  const SizedBox(width: 8),
                ],
                const _StatusPill(label: 'PENDING', color: _Palette.attention),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sent to ${controller.mobileNumberController.text}. Waiting for the '
                  'patient to confirm on their phone — this updates automatically.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.35),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _AliveButton(
                    variant: _ButtonVariant.primary,
                    color: _accent,
                    icon: Icons.refresh_rounded,
                    label: 'Check status',
                    loading: controller.isCheckingConsent.value,
                    onPressed: controller.isCheckingConsent.value ? null : controller.checkConsentStatusNow,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AliveButton(
                    variant: _ButtonVariant.tonal,
                    color: _accent,
                    icon: Icons.autorenew_rounded,
                    label: controller.consentResendSeconds.value == 0
                        ? 'Resend link'
                        : 'Resend ${controller.consentResendSeconds.value}s',
                    onPressed: controller.consentResendSeconds.value == 0 ? controller.resendConsentLink : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: _AliveButton(
                variant: _ButtonVariant.ghost,
                color: Colors.grey.shade700,
                icon: Icons.photo_camera_back_rounded,
                label: 'No response? Capture paper consent instead',
                loading: controller.isUploadingConsentPhoto.value,
                onPressed:
                controller.isUploadingConsentPhoto.value ? null : () => _showConsentSourceSheet(context, controller),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InitialState extends StatelessWidget {
  const _InitialState({super.key, required this.controller});

  final PatientRegistrationController controller;

  static const _accent = _Palette.attention;

  @override
  Widget build(BuildContext context) {
    return Obx(
          () => _ConsentShell(
        accent: _accent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _IconBadge(icon: Icons.shield_outlined, color: _accent),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'DPDP consent required before you can proceed',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _AliveButton(
                    variant: _ButtonVariant.primary,
                    color: _accent,
                    icon: Icons.send_rounded,
                    label: 'Send link',
                    loading: controller.isSendingConsentLink.value,
                    onPressed: controller.isSendingConsentLink.value ? null : controller.sendConsentLink,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AliveButton(
                    variant: _ButtonVariant.tonal,
                    color: _accent,
                    icon: Icons.photo_camera_back_rounded,
                    label: 'Paper consent',
                    loading: controller.isUploadingConsentPhoto.value,
                    onPressed: controller.isUploadingConsentPhoto.value
                        ? null
                        : () => _showConsentSourceSheet(context, controller),
                  ),
                ),
              ],
            ),
            /*if (controller.consentLinkError.value.isNotEmpty)
              _InlineBanner(message: controller.consentLinkError.value, color: _Palette.danger),
            if (controller.consentError.value.isNotEmpty)
              _InlineBanner(message: controller.consentError.value, color: _Palette.danger),*/
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Bottom sheet
// ─────────────────────────────────────────────────────────────────────────

void _showConsentSourceSheet(BuildContext context, PatientRegistrationController controller) {
  Get.bottomSheet(
    Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(999)),
          ),
          const Text('Capture paper consent', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            'Use this if the patient does not have a working mobile number',
            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          _SourceOptionTile(
            icon: Icons.camera_alt_rounded,
            color: _Palette.inProgress,
            title: 'Take photo',
            subtitle: 'Use the camera right now',
            onTap: () {
              Get.back();
              controller.pickConsentPhoto(ImageSource.camera);
            },
          ),
          const SizedBox(height: 10),
          _SourceOptionTile(
            icon: Icons.photo_library_rounded,
            color: const Color(0xFF9333EA),
            title: 'Choose from gallery',
            subtitle: 'Pick an existing photo',
            onTap: () {
              Get.back();
              controller.pickConsentPhoto(ImageSource.gallery);
            },
          ),
        ],
      ),
    ),
  );
}

class _SourceOptionTile extends StatelessWidget {
  const _SourceOptionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _IconBadge(icon: icon, color: color, size: 42, iconSize: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}