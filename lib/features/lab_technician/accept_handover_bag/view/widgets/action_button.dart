import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

import '../../controller/accept_bag_in_lab_controller.dart';

/// Accept + Scan Another buttons
class ActionButtons extends StatelessWidget {
  final AcceptBagInLabController controller;
  final ThemeData theme;
  const ActionButtons(
      {super.key, required this.controller, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Accept Bag
        Obx(() => SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: controller.isSubmitting.value
                ? null
                : controller.acceptBag,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
              theme.colorScheme.primary.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 4,
            ),
            child: controller.isSubmitting.value
                ? const SizedBox(
                height: 26,
                width: 26,
                child: CircularProgressIndicator(
                    strokeWidth: 3, color: Colors.white))
                : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 22),
                SizedBox(width: 10),
                Text('Accept Bag',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        )),

        const SizedBox(height: 12),

        // Scan Another
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: controller.resetScanner,
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                  color: theme.colorScheme.primary, width: 1.8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_scanner,
                    size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text('Scan Another Bag',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}