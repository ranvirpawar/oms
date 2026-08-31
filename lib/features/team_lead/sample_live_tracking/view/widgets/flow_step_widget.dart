import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_theme.dart';


import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../theme/app_theme.dart';
enum FlowStepState { idle, active, done }

class FlowStepData {
  final String iconAsset;
  final String label;
  final int count;
  final FlowStepState state;

  const FlowStepData({
    required this.iconAsset,
    required this.label,
    required this.count,
    this.state = FlowStepState.idle,
  });
}

/// Lays out steps in a "snake": row 1 flows left→right, row 2 flows
/// right→left (reversed), row 3 left→right again, etc. The turn between
/// rows always lands in the same column, so a straight down arrow works.
class FlowSnakeGrid extends StatelessWidget {
  final List<FlowStepData> steps;
  final double itemWidth;
  final int minItemsPerRow;
  final List<int>? rowSizes;

  const FlowSnakeGrid({
    super.key,
    required this.steps,
    this.itemWidth = 64,
    this.minItemsPerRow = 2,
    this.rowSizes = const [4, 3],
  });

  @override
  Widget build(BuildContext context) {
    if (rowSizes != null && rowSizes!.isNotEmpty) {
      return _buildSnakeFromRowSizes(rowSizes!);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final fitted = (maxWidth / itemWidth).floor();
        final itemsPerRow = fitted.clamp(minItemsPerRow, steps.length);
        return _buildSnake(_chunkFixed(itemsPerRow));
      },
    );
  }

  List<List<FlowStepData>> _chunkFixed(int itemsPerRow) {
    final List<List<FlowStepData>> rows = [];
    for (var i = 0; i < steps.length; i += itemsPerRow) {
      final end =
      (i + itemsPerRow > steps.length) ? steps.length : i + itemsPerRow;
      rows.add(steps.sublist(i, end));
    }
    return rows;
  }

  Widget _buildSnakeFromRowSizes(List<int> pattern) {
    final List<List<FlowStepData>> rows = [];
    var index = 0;
    var patternIdx = 0;
    while (index < steps.length) {
      final size = pattern[patternIdx % pattern.length];
      final end =
      (index + size > steps.length) ? steps.length : index + size;
      rows.add(steps.sublist(index, end));
      index = end;
      patternIdx++;
    }
    return _buildSnake(rows);
  }

  Widget _buildSnake(List<List<FlowStepData>> rows) {
    final rowWidgets = <Widget>[];

    for (var r = 0; r < rows.length; r++) {
      final isReversedRow = r.isOdd;
      final displayItems = isReversedRow ? rows[r].reversed.toList() : rows[r];
      final isLastRow = r == rows.length - 1;

      final children = <Widget>[];
      for (var i = 0; i < displayItems.length; i++) {
        final step = displayItems[i];
        children.add(
          FlowStepWidget(
            iconAsset: step.iconAsset,
            label: step.label,
            count: step.count,
            state: step.state,
          ),
        );
        if (i != displayItems.length - 1) {
          children.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Icon(
                isReversedRow ? Icons.arrow_back : Icons.arrow_forward,
                size: 12,
                color: AppColors.textTertiary,
              ),
            ),
          );
        }
      }

      rowWidgets.add(
        Row(
          // Always spread edge-to-edge, full row or partial trailing row.
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: children,
        ),
      );

      if (!isLastRow) {
        final alignRight = r.isEven;
        rowWidgets.add(
          Align(
            alignment: alignRight ? Alignment.centerRight : Alignment.centerLeft,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 2),
              child: Icon(Icons.arrow_downward, size: 12, color: AppColors.textTertiary),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rowWidgets,
    );
  }
}


class FlowStepWidget extends StatelessWidget {
  final String iconAsset;
  final String label;
  final int count;
  final FlowStepState state;

  const FlowStepWidget({
    super.key,
    required this.iconAsset,
    required this.label,
    required this.count,
    this.state = FlowStepState.idle,
  });

  @override
  Widget build(BuildContext context) {
    final isIdle = state == true;
    final isActive = state == true;
    /*final isIdle = state == FlowStepState.idle;
    final isActive = state == FlowStepState.active;*/

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 52,
          padding: EdgeInsets.all(isActive ? 3 : 0),
          decoration: isActive
              ? BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.blueLight,
            border: Border.all(color: AppColors.primary200, width: 1.5),
          )
              : null,
          child: Opacity(
            opacity: isIdle ? 0.35 : 1.0,
            child: Image.asset(
              iconAsset,
              height: isActive ? 42 : 48,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, textAlign: TextAlign.center, style: AppTextStyles.caption),
      ],
    );
  }
}
/*
enum FlowStepState { done, active, idle }

class FlowStepWidget extends StatelessWidget {
  final String iconAsset;
  final String label;
  final int count;
  final FlowStepState state;
  final bool showArrow;

  const FlowStepWidget({
    super.key,
    required this.iconAsset,
    required this.label,
    required this.count,
    this.state = FlowStepState.idle,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    final isIdle = state == true;
    final isActive = state == true;*/
/*final isIdle = state == FlowStepState.idle;
    final isActive = state == FlowStepState.active;*//*


    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon badge — height fixed, width derived from the
            // asset's own aspect ratio so nothing gets stretched.
            Container(
              height: 52,
              padding: EdgeInsets.all(isActive ? 3 : 0),
              decoration: isActive
                  ? BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.blueLight,
                border: Border.all(
                  color: AppColors.primary200,
                  width: 1.5,
                ),
              )
                  : null,
              child: Opacity(
                opacity: isIdle ? 0.35 : 1.0,
                child: Image.asset(
                  iconAsset,
                  height: isActive ? 42 : 48,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ],
        ),
        if (showArrow) ...[
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Icon(
              Icons.arrow_forward,
              size: 12,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ],
    );
  }
}
*/
