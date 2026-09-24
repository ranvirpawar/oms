import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Mirrors the dashboard metric strip while its summary request is in flight.
class DashboardStatsShimmer extends StatelessWidget {
  final int itemCount;

  const DashboardStatsShimmer({super.key, required this.itemCount})
    : assert(itemCount > 0);

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    return Semantics(
      label: 'Loading dashboard statistics',
      liveRegion: true,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Shimmer.fromColors(
              baseColor: const Color(0xFFE4E7EE),
              highlightColor: const Color(0xFFF7F8FB),
              period: const Duration(milliseconds: 1400),
              enabled: !MediaQuery.disableAnimationsOf(context),
              child: Row(
                children: List.generate(itemCount * 2 - 1, (index) {
                  if (index.isOdd) {
                    return Container(width: 1, height: 40, color: Colors.white);
                  }
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: itemCount > 3
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.center,
                        children: [
                          _placeholder(width: 42, height: textScaler.scale(23)),
                          const SizedBox(height: 6),
                          FractionallySizedBox(
                            widthFactor: 0.85,
                            child: _placeholder(height: textScaler.scale(10)),
                          ),
                          const SizedBox(height: 4),
                          FractionallySizedBox(
                            widthFactor: 0.65,
                            child: _placeholder(height: textScaler.scale(10)),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder({double? width, required double height}) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(5),
    ),
  );
}
