import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/model/sample_collection_models.dart';

import '../controller/sample_collection_controller.dart';
import 'barcode_validator.dart';

enum BarcodeCheckStatus { idle, checking, available, unavailable, duplicate, formatError, error }
class SampleBarcodeEntry {
  final int sampleTypeId;
  final String sampleType;
  final String volumeRequiredMl;
  final List<TestInfo> tests;

  final TextEditingController barcodeController = TextEditingController(
    text: BarcodeValidator.prefix,
  );

  final Rx<SampleCollectionStatus> status = SampleCollectionStatus.pending.obs;

  final Rx<BarcodeCheckStatus> barcodeStatus = BarcodeCheckStatus.idle.obs;
  final RxString barcodeMessage = ''.obs;
  Timer? _barcodeDebounce;

  void debounceBarcodeCheck(
      VoidCallback action, {
        Duration delay = const Duration(milliseconds: 1000),
      }) {
    _barcodeDebounce?.cancel();
    _barcodeDebounce = Timer(delay, action);
  }

  final RxMap<int, TestIncompleteInfo> testIncompleteMap = <int, TestIncompleteInfo>{}.obs;
  final RxBool isScanning = false.obs;

  final List<TubeTypeInfo> apiTubeTypes;

  /// Cap on manually-added tubes, per sample.
  static const int maxManualTubes = 3;

  /// Extra tubes added via the inline "+1" on a tube-type row. Each is
  /// tagged with the type it was added against but mirrors the sample's
  /// single [barcodeController] for display, same as any other non-primary
  /// row — it doesn't carry its own barcode value.
  final RxList<ManualTubeEntry> manualTubes = <ManualTubeEntry>[].obs;

  SampleBarcodeEntry({
    required this.sampleTypeId,
    required this.sampleType,
    required this.volumeRequiredMl,
    required this.tests,
  }) : apiTubeTypes = _dedupeTubeTypes(tests) {
    barcodeController.selection = const TextSelection.collapsed(
      offset: BarcodeValidator.prefix.length,
    );
  }

  bool get canAddManualTube => manualTubes.length < maxManualTubes;

  /// Rows for the UI: each API tube type, immediately followed by any
  /// manual tubes added against that specific type — so a manual add
  /// visually sits right under the row its "+1" was tapped on.
  List<TubeRowData> get tubeRows {
    if (apiTubeTypes.isEmpty) {
      return [
        TubeRowData(id: 'default', name: 'Tube', isManual: false),
        ...manualTubes.map(
              (m) => TubeRowData(id: m.id, name: m.tubeType, isManual: true, tubeTypeId: m.tubeTypeId),
        ),
      ];
    }

    final rows = <TubeRowData>[];
    for (final tube in apiTubeTypes) {
      rows.add(
        TubeRowData(
          id: 'api-${tube.tubeTypeId}',
          name: tube.tubeType,
          isManual: false,
          tubeTypeId: tube.tubeTypeId,
        ),
      );
      for (final manual in manualTubes.where((m) => m.tubeTypeId == tube.tubeTypeId)) {
        rows.add(
          TubeRowData(id: manual.id, name: manual.tubeType, isManual: true, tubeTypeId: manual.tubeTypeId),
        );
      }
    }
    return rows;
  }

  /// Adds a manual duplicate of [tubeType]/[tubeTypeId]. Returns false if
  /// the per-sample cap is already hit.
  bool addManualTube({required int tubeTypeId, required String tubeType}) {
    if (!canAddManualTube) return false;
    manualTubes.add(
      ManualTubeEntry(
        id: 'manual-${DateTime.now().microsecondsSinceEpoch}',
        tubeTypeId: tubeTypeId,
        tubeType: tubeType,
      ),
    );
    return true;
  }

  void removeManualTube(String id) {
    final idx = manualTubes.indexWhere((tube) => tube.id == id);
    if (idx == -1) return;
    manualTubes[idx].dispose();
    manualTubes.removeAt(idx);
  }

  static List<TubeTypeInfo> _dedupeTubeTypes(List<TestInfo> tests) {
    final seen = <int>{};
    final result = <TubeTypeInfo>[];
    for (final test in tests) {
      for (final tube in test.tubeTypes) {
        if (seen.add(tube.tubeTypeId)) result.add(tube);
      }
    }
    return result;
  }

  int get tubeCount {
    final count = apiTubeTypes.length + manualTubes.length;
    return count > 0 ? count : 1;
  }

  bool get isCollected => status.value == SampleCollectionStatus.collected;
  bool get isPending => status.value == SampleCollectionStatus.pending;
  bool get isFullyUnusable => tests.isNotEmpty && testIncompleteMap.length == tests.length;
  bool get hasPartialIncomplete => testIncompleteMap.isNotEmpty && !isFullyUnusable;
  bool get isResolved => isCollected || isFullyUnusable;

  void dispose() {
    _barcodeDebounce?.cancel();
    barcodeController.dispose();
    for (final tube in manualTubes) {
      tube.dispose();
    }
  }
}
/*
class SampleBarcodeEntry {
  final int sampleTypeId;
  final String sampleType;
  final String volumeRequiredMl;
  final List<TestInfo> tests;

  final TextEditingController barcodeController = TextEditingController(
    text: BarcodeValidator.prefix,
  );

  final Rx<SampleCollectionStatus> status =
      SampleCollectionStatus.pending.obs;

  // ── Barcode verification (server-checked availability) ──────────────────
  final Rx<BarcodeCheckStatus> barcodeStatus = BarcodeCheckStatus.idle.obs;
  final RxString barcodeMessage = ''.obs;
  Timer? _barcodeDebounce;

  void debounceBarcodeCheck(
      VoidCallback action, {
        Duration delay = const Duration(milliseconds: 1000),
      }) {
    _barcodeDebounce?.cancel();
    _barcodeDebounce = Timer(delay, action);
  }

  final RxMap<int, TestIncompleteInfo> testIncompleteMap =
      <int, TestIncompleteInfo>{}.obs;

  final RxBool isScanning = false.obs;

  // ── Tube type details from API ────────────────────────────────────────────
  /// Unique tube types required across this sample's tests.
  ///
  /// The order is preserved based on the first occurrence in [tests].
  /// One barcode row is shown per tube type.
  ///
  /// All API tube rows share [barcodeController], so entering a barcode
  /// in one row mirrors it to the other API tube rows automatically.
  final List<TubeTypeInfo> apiTubeTypes;

  /// Tubes manually added by the phlebotomist using "+ Tube".
  ///
  /// Kept separate from [apiTubeTypes] so that only manually added tubes
  /// can be removed.
  final RxList<ManualTubeEntry> manualTubes = <ManualTubeEntry>[].obs;

  SampleBarcodeEntry({
    required this.sampleTypeId,
    required this.sampleType,
    required this.volumeRequiredMl,
    required this.tests,
  }) : apiTubeTypes = _dedupeTubeTypes(tests) {
    // Critical: put the cursor AFTER the prefix so the user types
    // digits immediately.
    barcodeController.selection = const TextSelection.collapsed(
      offset: BarcodeValidator.prefix.length,
    );
  }

  /// Combined list used by the UI to render tube rows.
  ///
  /// API-provided tubes cannot be removed.
  /// Manually added tubes can be removed.
  List<TubeRowData> get tubeRows => [
    for (final tube in apiTubeTypes)
      TubeRowData(
        id: 'api-${tube.tubeTypeId}',
        name: tube.tubeType,
        isManual: false,
      ),
    for (final tube in manualTubes)
      TubeRowData(
        id: tube.id,
        name: tube.nameController.text,
        isManual: true,
        nameController: tube.nameController,
      ),
  ];

  /// Add a tube manually from the "+ Tube" action.
  void addManualTube() {
    final nextNumber = apiTubeTypes.length + manualTubes.length + 1;
    final tube = ManualTubeEntry(
      id: 'manual-${DateTime.now().microsecondsSinceEpoch}',
    );
    tube.nameController.text = 'Tube $nextNumber';
    manualTubes.add(tube);
  }

  /// Remove only a manually added tube.
  ///
  /// API-provided tubes are never part of [manualTubes], so they cannot
  /// accidentally be removed through this method.
  void removeManualTube(String id) {
    final idx = manualTubes.indexWhere((tube) => tube.id == id);

    if (idx == -1) return;

    manualTubes[idx].dispose();
    manualTubes.removeAt(idx);
  }

  /// Extract unique tube types from all tests while preserving
  /// the first-seen order.
  static List<TubeTypeInfo> _dedupeTubeTypes(List<TestInfo> tests) {
    final seen = <int>{};
    final result = <TubeTypeInfo>[];

    for (final test in tests) {
      for (final tube in test.tubeTypes) {
        if (seen.add(tube.tubeTypeId)) {
          result.add(tube);
        }
      }
    }

    return result;
  }
  int get tubeCount {
    final count = apiTubeTypes.length + manualTubes.length;
    return count > 0 ? count : 1;
  }
  bool get isCollected =>
      status.value == SampleCollectionStatus.collected;

  bool get isPending =>
      status.value == SampleCollectionStatus.pending;

  bool get isFullyUnusable =>
      tests.isNotEmpty && testIncompleteMap.length == tests.length;

  bool get hasPartialIncomplete =>
      testIncompleteMap.isNotEmpty && !isFullyUnusable;

  bool get isResolved =>
      isCollected || isFullyUnusable;

  void dispose() {
    _barcodeDebounce?.cancel();

    barcodeController.dispose();

    // Dispose controllers belonging to manually added tubes.
    for (final tube in manualTubes) {
      tube.dispose();
    }
  }
}*/
