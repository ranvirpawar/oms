import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/model/sample_collection_models.dart';

import '../controller/sample_collection_controller.dart';

enum BarcodeCheckStatus { idle, checking, available, unavailable, duplicate, formatError, error }

class SampleBarcodeEntry {
  final int sampleTypeId;
  final String sampleType;
  final String volumeRequiredMl;
  final List<TestInfo> tests;

  final TextEditingController barcodeController = TextEditingController();
  final Rx<SampleCollectionStatus> status = SampleCollectionStatus.pending.obs;

  // ── Barcode verification (server-checked availability) ──────────────────
  final Rx<BarcodeCheckStatus> barcodeStatus = BarcodeCheckStatus.idle.obs;
  final RxString barcodeMessage = ''.obs;
  Timer? _barcodeDebounce;

  void debounceBarcodeCheck(
      VoidCallback action, {
        Duration delay = const Duration(milliseconds: 500),
      }) {
    _barcodeDebounce?.cancel();
    _barcodeDebounce = Timer(delay, action);
  }

  final RxMap<int, TestIncompleteInfo> testIncompleteMap =
      <int, TestIncompleteInfo>{}.obs;

  final RxBool isScanning = false.obs;

  SampleBarcodeEntry({
    required this.sampleTypeId,
    required this.sampleType,
    required this.volumeRequiredMl,
    required this.tests,
  });

  bool get isCollected => status.value == SampleCollectionStatus.collected;
  bool get isPending => status.value == SampleCollectionStatus.pending;
  bool get isFullyUnusable =>
      tests.isNotEmpty && testIncompleteMap.length == tests.length;
  bool get hasPartialIncomplete =>
      testIncompleteMap.isNotEmpty && !isFullyUnusable;
  bool get isResolved => isCollected || isFullyUnusable;

  void dispose() {
    _barcodeDebounce?.cancel();
    barcodeController.dispose();
  }
}