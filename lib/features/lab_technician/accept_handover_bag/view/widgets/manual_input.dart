import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../controller/accept_bag_in_lab_controller.dart';

class ManualInputField extends StatelessWidget {
  final AcceptBagInLabController controller;
  final bool isDark;
  const ManualInputField(
      {super.key, required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller.manualBarcodeController,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: 'Enter bag barcode manually',
            prefixIcon: const Icon(Icons.qr_code_2),
            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_forward_ios),
              onPressed: () {
                final value =
                controller.manualBarcodeController.text.trim();
                if (value.isNotEmpty) {
                  controller.onManualBarcodeSubmit(value);
                }
              },
            ),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16)),
            filled: true,
            fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              controller.onManualBarcodeSubmit(value.trim());
            }
          },
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

class EmptyPlaceholder extends StatelessWidget {
  final ThemeData theme;
  const EmptyPlaceholder({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.qr_code_scanner,
                size: 80,
                color: theme.disabledColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Scan or enter a bag barcode above',
              style: TextStyle(
                  fontSize: 15,
                  color: theme.textTheme.bodyMedium?.color
                      ?.withOpacity(0.55)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}