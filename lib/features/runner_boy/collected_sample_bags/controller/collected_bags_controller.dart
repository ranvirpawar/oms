import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../network/app_error.dart';
import '../../../../services/user_service.dart';
import '../../../../utils/ui_designs/liquid_snackbar.dart';
import '../../../auth/model/login_response_model.dart';
import '../model/collected_bag_model.dart';
import '../model/connector_model.dart';
import '../service/collected_bags_service.dart';


import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'collected_bags_extension.dart';


enum SubmissionState { idle, processing, success, error }

class CollectedBagsController extends GetxController {
  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final Rx<String> userId = ''.obs;
  final UserService userService = Get.put(UserService());
  final CollectedBagsService bagsService = CollectedBagsService();

  // State
  final Rx<SubmissionState> submissionState = SubmissionState.idle.obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // Bags data
  final RxList<QRBag> bagsList = <QRBag>[].obs;
  // filteredBagsList is a computed getter (see below)
  final RxString searchQuery = ''.obs;

  // Multi-selection (kept as RxSet<int> – do not change type)
  final RxSet<int> selectedSessionIds = <int>{}.obs;

  // Submission progress tracking
  final RxInt submissionProgress = 0.obs;
  final RxInt submissionTotal = 0.obs;
  final RxList<String> submissionErrors = <String>[].obs;

  // ── Filter / sort state ───────────────────────────────────────────────
  final Rx<TatFilter> statusFilter = TatFilter.all.obs;
  final RxnString facilityFilter = RxnString();
  final RxString sortOption = 'newest'.obs; // 'newest' | 'oldest' | 'tubes'

  // ── Handover (unchanged) ────────────────────────────────────────────
  final Rxn<Connector> selectedConnector = Rxn<Connector>();
  final RxBool isHandOverToRunnerBoy = true.obs;
  final RxList<Connector> runnerBoyList = <Connector>[].obs;
  final RxBool isFetchingRunnerBoys = false.obs;
  final RxInt currentHandoverTab = 0.obs;

  @override
  void onInit() {
    loadUser();
    super.onInit();
  }

  void loadUser() async {
    try {
      final userData = await userService.getUser();
      if (userData != null) {
        user.value = userData;
        userId.value = user.value?.empCode.toString() ?? '';
        debugPrint('✅ User loaded: ${user.value?.name}');
        fetchBags();
      } else {
        debugPrint('❌ Failed to load user');
      }
    } catch (e) {
      debugPrint('❌ Error loading user: $e');
    }
  }

  Future<void> fetchBags() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';
      selectedSessionIds.clear();

      if (userId.value.isEmpty) throw Exception('User ID not found');

      final response =
      await bagsService.getCollectedQRBagDetails(int.parse(userId.value));

      if (response.isSuccess && response.output != null) {
        bagsList.value = response.output!;
        debugPrint('✅ Loaded ${bagsList.length} bags');
      } else {
        bagsList.value = [];
      }
    } catch (e) {
      if (e is AppError && e.isSessionTerminal) {
        // Session death is handled centrally (one "Session expired"
        // message + redirect to Login) — don't render a second, garbled
        // error toast for this screen's in-flight request.
        return;
      }
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      _showSnackbar('Error', errorMessage.value, isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Selection (unchanged) ───────────────────────────────

  void toggleBagSelection(QRBag bag) {
    HapticFeedback.selectionClick();
    if (selectedSessionIds.contains(bag.sessionId)) {
      selectedSessionIds.remove(bag.sessionId);
    } else {
      selectedSessionIds.add(bag.sessionId);
    }
  }

  bool isBagSelected(QRBag bag) => selectedSessionIds.contains(bag.sessionId);

  bool get hasSelection => selectedSessionIds.isNotEmpty;

  int get selectionCount => selectedSessionIds.length;

  List<QRBag> get selectedBags =>
      bagsList.where((b) => selectedSessionIds.contains(b.sessionId)).toList();

  void clearSelection() {
    selectedSessionIds.clear();
  }

  void selectAll() {
    for (final bag in filteredBagsList) {
      selectedSessionIds.add(bag.sessionId);
    }
  }

  // ─── Search ────────────────────────────────────────────────

  void searchBags(String query) {
    searchQuery.value = query;
  }

  void clearSearch() {
    searchQuery.value = '';
  }

  // ─── TAT helpers used by the view ─────────────────────────

  TatInfo tatFor(QRBag bag) => TatHelper.evaluate(
    collectedAt: bag.collectedAt,
    tubeCount: bag.tubeCount,
  );

  // ─── Derived getters used by the view ─────────────────────

  /// Same as filteredBagsList but ignoring the status filter — used to
  /// show the correct count on the "All" chip.
  List<QRBag> get filteredBagsListUnfiltered =>
      _applyNonStatusFilters(bagsList);

  /// The list the view actually renders.
  List<QRBag> get filteredBagsList {
    var list = _applyNonStatusFilters(bagsList);

    final targetStatus = statusFilter.value.toStatus;
    if (targetStatus != null) {
      list = list.where((bag) => tatFor(bag).status == targetStatus).toList();
    }

    list.sort((a, b) {
      switch (sortOption.value) {
        case 'oldest':
          return a.collectedAt.compareTo(b.collectedAt);
        case 'tubes':
          return b.tubeCount.compareTo(a.tubeCount);
        case 'newest':
        default:
          return b.collectedAt.compareTo(a.collectedAt);
      }
    });

    return list;
  }

  List<QRBag> _applyNonStatusFilters(List<QRBag> source) {
    return source.where((bag) {
      if (facilityFilter.value != null &&
          bag.facilityName != facilityFilter.value) {
        return false;
      }
      if (searchQuery.value.isNotEmpty &&
          !bag.bagcode
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  List<String> get availableFacilities {
    final names = bagsList.map((b) => b.facilityName).toSet().toList();
    names.sort();
    return names;
  }

  int get onTrackCount =>
      bagsList.where((b) => tatFor(b).status == TatStatus.onTrack).length;

  int get dueSoonCount =>
      bagsList.where((b) => tatFor(b).status == TatStatus.dueSoon).length;

  int get overdueCount =>
      bagsList.where((b) => tatFor(b).status == TatStatus.overdue).length;

  int get emptyBagCount =>
      bagsList.where((b) => tatFor(b).status == TatStatus.empty).length;

  /// Bags that genuinely need the Runner's attention right now.
  int get needsAttentionCount => overdueCount + dueSoonCount;

  // ─── Submission (unchanged) ───────────────────────────────

  /// Submit to Lab (type=1). handoverUserId = userId (same person).
  Future<void> submitToLab() async {
    if (!hasSelection) {
      _showSnackbar('Required', 'Please select at least one bag',
          isWarning: true);
      return;
    }

    await _runBatchSubmission(type: 1);
  }

  /// Handover to Runner Boy / lab staff (type=2). Prompts for their ID.
  Future<void> handoverToConnector(int connectorUserId) async {
    if (!hasSelection) {
      _showSnackbar('Required', 'Please select at least one bag',
          isWarning: true);
      return;
    }

    await _runBatchSubmission(type: 2, handoverUserId: connectorUserId);
  }

  Future<void> _runBatchSubmission({
    required int type,
    int? handoverUserId,
  }) async {
    try {
      submissionState.value = SubmissionState.processing;
      submissionErrors.clear();
      submissionProgress.value = 0;

      final bags = selectedBags;
      submissionTotal.value = bags.length;

      final uid = int.parse(userId.value);
      final huid = handoverUserId ?? uid;

      for (final bag in bags) {
        try {
          final response = await bagsService.submitQRBagToLabOrHandover(
            type: type,
            fromSession: bag.sessionId,
            submittedBy: uid,
            handoverUserId: huid,
          );

          if (!response.isSuccess) {
            submissionErrors.add('Bag ${bag.bagcode}: ${response.message}');
          }
        } catch (e) {
          submissionErrors.add(
              'Bag ${bag.bagcode}: ${e.toString().replaceAll('Exception: ', '')}');
        }
        submissionProgress.value++;
      }

      final successCount = bags.length - submissionErrors.length;
      final label = type == 1 ? 'Lab' : 'Runner Boy';

      if (submissionErrors.isEmpty) {
        submissionState.value = SubmissionState.success;

        _showSnackbar(
          'Success',
          '$successCount bag(s) submitted to $label successfully',
        );
      } else if (successCount > 0) {
        submissionState.value = SubmissionState.success;
        _showSnackbar(
          'Partial Success',
          '$successCount submitted, ${submissionErrors.length} failed',
          isWarning: true,
        );
      } else {
        submissionState.value = SubmissionState.error;
        _showSnackbar(
          'Failed',
          'All submissions failed. Please try again.',
          isError: true,
        );
        submissionState.value = SubmissionState.idle;
      }
      await Future.delayed(const Duration(milliseconds: 300));
      await fetchBags();
    } catch (e) {
      submissionState.value = SubmissionState.error;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      _showSnackbar('Error', errorMessage.value, isError: true);
      submissionState.value = SubmissionState.idle;
    }
  }

  void _showSnackbar(
      String title,
      String message, {
        bool isError = false,
        bool isWarning = false,
      }) {
    if (isError) {
      LiquidSnack.error(message, title: title);
    } else if (isWarning) {
      LiquidSnack.warning(message, title: title);
    } else {
      LiquidSnack.success(message, title: title);
    }
  }

  void reset() {
    selectedSessionIds.clear();
    errorMessage.value = '';
    submissionState.value = SubmissionState.idle;
    searchQuery.value = '';
    facilityFilter.value = null;
    statusFilter.value = TatFilter.all;
    sortOption.value = 'newest';
  }

  //---------- Handover to lab staff / runner boy (unchanged) -----------

  final RxnString runnerBoyError = RxnString();          // friendly message or null
  final RxBool hasLoadedRunnerBoys = false.obs;          // avoids "empty" flash on first frame


// 2) REPLACE initHandoverPage / resetHandoverPage / fetchRunnerBoys ----------

  void initHandoverPage() {
    selectedConnector.value = null;
    searchQuery.value = '';
    isHandOverToRunnerBoy.value = true;
    submissionState.value = SubmissionState.idle;
    submissionErrors.clear();
    runnerBoyError.value = null;
    hasLoadedRunnerBoys.value = false;
    fetchRunnerBoys();
  }

  void resetHandoverPage() {
    runnerBoyList.clear();
    selectedConnector.value = null;
    searchQuery.value = '';
    submissionState.value = SubmissionState.idle;
    submissionErrors.clear();
    runnerBoyError.value = null;
    hasLoadedRunnerBoys.value = false;
  }

  Future<void> fetchRunnerBoys() async {
    try {
      isFetchingRunnerBoys.value = true;
      runnerBoyError.value = null;

      final list = await bagsService.getConnectorList('3', userId.value);
      runnerBoyList.value = list;

      // If the previously selected person is no longer in the list, clear it.
      final sel = selectedConnector.value;
      if (sel != null && !list.any((e) => e.userId == sel.userId)) {
        selectedConnector.value = null;
      }
    } catch (e) {
      // Session death is handled centrally (redirect to Login).
      if (e is AppError && e.isSessionTerminal) return;

      // Never surface the raw exception — log it, show a friendly retry state.
      debugPrint('❌ fetchRunnerBoys failed: $e');
      runnerBoyList.clear();
      runnerBoyError.value =
      'Please check your connection and try again.';
    } finally {
      hasLoadedRunnerBoys.value = true;
      isFetchingRunnerBoys.value = false;
    }
  }


// 3) REPLACE filteredConnectors (adds clinic search) -------------------------

  List<Connector> get filteredConnectors {
    final source = runnerBoyList;
    final q = searchQuery.value.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source
        .where((c) =>
    c.userName.toLowerCase().contains(q) ||
        c.userId.toString().contains(q) ||
        c.facilityName.toLowerCase().contains(q))
        .toList();
  }


  bool get isCurrentTabLoading => isFetchingRunnerBoys.value;

  void selectConnector(Connector connector) {
    selectedConnector.value = connector;
  }
}