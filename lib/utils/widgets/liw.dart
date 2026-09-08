import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../ui_designs/liquid_snackbar.dart';

class SnackDemoScreen extends StatelessWidget {
  const SnackDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liquid Snack',),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          const _SectionLabel('Quick (minimal pill)'),
          _DemoRow(
            label: 'Copied',
            hint: 'Bare confirmation, nothing to act on',
            onTap: () => LiquidSnack.quick('Copied'),
          ),
          _DemoRow(
            label: 'Added to favorites',
            hint: 'Quick pill, top position',
            onTap: () => LiquidSnack.quick(
              'Added to favorites',
              position: SnackPosition.top,
            ),
          ),

          const _SectionLabel('Standard feedback (full card)'),
          _DemoRow(
            label: 'Success',
            hint: 'Action completed, nothing more needed',
            onTap: () => LiquidSnack.success(
              'Your changes have been saved.',
              title: 'Saved',
            ),
          ),
          _DemoRow(
            label: 'Error',
            hint: 'Failed, no inline fix offered here',
            onTap: () => LiquidSnack.error(
              'Check your connection and try again.',
              title: 'Upload failed',
            ),
          ),
          _DemoRow(
            label: 'Warning',
            hint: 'Went through, but with a caveat',
            onTap: () => LiquidSnack.warning(
              'You have 2 days left on your plan.',
              title: 'Trial ending soon',
            ),
          ),
          _DemoRow(
            label: 'Info',
            hint: 'Neutral, non-urgent update',
            onTap: () => LiquidSnack.info(
              'A new version is ready to install.',
              title: 'Update available',
            ),
          ),

          const _SectionLabel('With action'),
          _DemoRow(
            label: 'Undo delete',
            hint: 'Actionable — carries a real onAction',
            onTap: () => LiquidSnack.withAction(
              message: 'Conversation deleted.',
              actionLabel: 'Undo',
              onAction: () => LiquidSnack.quick('Restored'),
              variant: SnackVariant.neutral,
            ),
          ),
          _DemoRow(
            label: 'Retry failed action',
            hint: 'Error + immediate fix, not a bare error()',
            onTap: () => LiquidSnack.withAction(
              message: 'Message failed to send.',
              actionLabel: 'Retry',
              onAction: () => LiquidSnack.success('Message sent.'),
              variant: SnackVariant.error,
            ),
          ),

          const _SectionLabel('Edge cases worth checking'),
          _DemoRow(
            label: 'Long message wrap',
            hint: 'Confirms text wraps and stays legible over 2+ lines',
            onTap: () => LiquidSnack.info(
              'This is a longer message to check that multi-line text '
                  'still wraps cleanly and stays readable against the glass '
                  'surface without truncating awkwardly.',
              title: 'Long content test',
            ),
          ),
          _DemoRow(
            label: 'Queue 3 at once',
            hint: 'Confirms queueing instead of stacking glass panels',
            onTap: () {
              LiquidSnack.info('First message');
              LiquidSnack.warning('Second message');
              LiquidSnack.success('Third message');
            },
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Demo-only building blocks (press feedback, no ripple) — not part of the
// snackbar system itself, just makes the test screen pleasant to tap through.
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        text.toUpperCase(),

      ),
    );
  }
}

class _DemoRow extends StatefulWidget {
  final String label;
  final String hint;
  final VoidCallback onTap;
  const _DemoRow({required this.label, required this.hint, required this.onTap});

  @override
  State<_DemoRow> createState() => _DemoRowState();
}

class _DemoRowState extends State<_DemoRow> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,

                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.hint,

                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}