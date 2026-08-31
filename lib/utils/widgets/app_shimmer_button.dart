import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AppShimmerButton extends StatefulWidget {
  const AppShimmerButton({
    super.key,
    required this.text,
    required this.onTap,
    this.icon,
  });

  final String text;
  final VoidCallback onTap;
  final Widget? icon;

  @override
  State<AppShimmerButton> createState() => _AppShimmerButtonState();
}

class _AppShimmerButtonState extends State<AppShimmerButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();

    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _shimmer,
        builder: (_, child) {
          return Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.30),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  child!,

                  Positioned.fill(
                    child: FractionalTranslation(
                      translation: Offset(
                        (_shimmer.value * 3) - 1.5,
                        0,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.15),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.1,
                ),
              ),

              if (widget.icon != null) ...[
                const SizedBox(width: 8),
                widget.icon!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}