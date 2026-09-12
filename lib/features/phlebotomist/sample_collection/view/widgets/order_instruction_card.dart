import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../theme/app_colors.dart';

class OrderInstructionsCard extends StatefulWidget {
  final bool fastingRequired;
  final String? fastingNote;
  final List<String> specialInstructions;
  final bool initiallyExpanded;
  final bool floating;

  const OrderInstructionsCard({
    super.key,
    this.fastingRequired = false,
    this.fastingNote,
    this.specialInstructions = const [],
    this.initiallyExpanded = false,
    this.floating = false,
  });

  @override
  State<OrderInstructionsCard> createState() => _OrderInstructionsCardState();
}

class _OrderInstructionsCardState extends State<OrderInstructionsCard> {
  late bool _expanded = widget.initiallyExpanded;

  bool get hasContent =>
      (widget.fastingRequired && (widget.fastingNote?.isNotEmpty ?? false)) ||
          widget.specialInstructions.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (!hasContent) return const SizedBox.shrink();

    final card = Container(
      width: double.infinity,
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
            // Header
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _expanded = !_expanded);
              },
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.amberLight.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: AppColors.amberText,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Instructions',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 22,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: !_expanded
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    if (widget.fastingRequired &&
                        (widget.fastingNote?.isNotEmpty ?? false)) ...[
                      Text(
                        widget.fastingNote!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      if (widget.specialInstructions.isNotEmpty)
                        const SizedBox(height: 10),
                    ],
                    for (final instruction in widget.specialInstructions)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '•  ',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                instruction,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (!widget.floating) return card;

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