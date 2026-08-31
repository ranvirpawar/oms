import 'package:flutter/material.dart';

class SectionHeaderContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? color;

  const SectionHeaderContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    this.borderRadius = 16.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final defaultColor = Theme.of(context).colorScheme.primary.withOpacity(1);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(borderRadius),
          topRight: Radius.circular(borderRadius),
        ),
        color: color ?? defaultColor,
      ),
      child: child,
    );
  }
}
