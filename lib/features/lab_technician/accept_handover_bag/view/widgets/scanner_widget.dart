import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../controller/accept_bag_in_lab_controller.dart';

class CollapsedScannerHeader extends StatelessWidget {
  final AcceptBagInLabController controller;
  const CollapsedScannerHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.black87, Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.qr_code_scanner, color: Colors.white, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Scanned: ${controller.scannedBarcode.value ?? '—'}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                const Text('Tap camera icon to scan another',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            onPressed: controller.resetScanner,
          ),
        ],
      ),
    );
  }
}

class ScannerHint extends StatelessWidget {
  final bool active;
  const ScannerHint({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.black54, borderRadius: BorderRadius.circular(12)),
      child: Text(
        active ? 'Align bag barcode within the frame' : 'Processing…',
        textAlign: TextAlign.center,
        style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}