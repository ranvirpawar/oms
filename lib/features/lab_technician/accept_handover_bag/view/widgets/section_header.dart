import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final ThemeData theme;
  const SectionHeader({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.inventory_2,
              color: theme.colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text('Bag Details',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary)),
      ],
    );
  }
}