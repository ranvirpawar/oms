import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RunnerAction {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const RunnerAction({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class RunnerActionFab extends StatefulWidget {
  final List<RunnerAction> actions;
  const RunnerActionFab({super.key, required this.actions});

  @override
  State<RunnerActionFab> createState() => _RunnerActionFabState();
}

class _RunnerActionFabState extends State<RunnerActionFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.mediumImpact();
    setState(() => _open = !_open);
    _open ? _c.forward() : _c.reverse();
  }

  Future<void> _select(RunnerAction a) async {
    HapticFeedback.selectionClick();
    setState(() => _open = false);
    await _c.reverse();
    a.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final n = widget.actions.length;

    return Stack(
      children: [
        // Scrim + blur
        IgnorePointer(
          ignoring: !_open,
          child: FadeTransition(
            opacity: CurvedAnimation(parent: _c, curve: Curves.easeOut),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggle,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.black.withOpacity(0.35)),
              ),
            ),
          ),
        ),

        Positioned(
          right: 18,
          bottom: 20 + bottomInset,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Action pills (index 0 = top). Nearest to FAB animates first.
              for (int i = 0; i < n; i++) _buildItem(i, n),
              const SizedBox(height: 4),
              _buildMainButton(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItem(int i, int n) {
    final fromBottom = n - 1 - i;
    final start = (fromBottom * 0.12).clamp(0.0, 0.6);
    final end = (start + 0.55).clamp(0.0, 1.0);

    // Fade: no overshoot, so it stays safely within 0..1
    final fade = CurvedAnimation(
      parent: _c,
      curve: Interval(start, end, curve: Curves.easeOut),
      reverseCurve: Curves.easeIn,
    );

    // Slide: overshoot is fine here (the "back" bounce)
    final slide = CurvedAnimation(
      parent: _c,
      curve: Interval(start, end, curve: Curves.easeOutBack),
      reverseCurve: Curves.easeIn,
    );

    final a = widget.actions[i];

    return IgnorePointer(
      ignoring: !_open,
      child: FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: slide.drive(
            Tween(begin: const Offset(0.25, 0.6), end: Offset.zero),
          ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ActionPill(action: a, onTap: () => _select(a)),
          ),
        ),
      ),
    );
  }

  Widget _buildMainButton() {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Container(
          height: 58,
          padding: EdgeInsets.symmetric(horizontal: _open ? 18 : 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.4),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.rotate(
                angle: _c.value * 0.785398 * 3, // 135° → bolt turns to X feel
                child: Icon(
                  _open ? Icons.close_rounded : Icons.bolt_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _open
                    ? const SizedBox.shrink()
                    : const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text('Start Task',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  final RunnerAction action;
  final VoidCallback onTap;
  const _ActionPill({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(action.label,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF161A2B))),
                  const SizedBox(height: 2),
                  Text(action.subtitle,
                      style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(width: 12),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: action.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(action.icon, color: action.color, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}