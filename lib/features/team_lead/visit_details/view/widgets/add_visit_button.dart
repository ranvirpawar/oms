import 'package:flutter/material.dart';

class AddVisitButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AddVisitButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('Add New Visit'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}