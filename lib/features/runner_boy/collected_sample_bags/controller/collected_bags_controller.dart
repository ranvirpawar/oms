import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../services/user_service.dart';
import '../../../auth/model/login_response_model.dart';
import '../../handover_to_connector/model/connector_model.dart';
import '../model/collected_bag_model.dart';
import '../service/collected_bags_service.dart';

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
  final RxList<QRBag> filteredBagsList = <QRBag>[].obs;
  final RxString searchQuery = ''.obs;

  // Multi-selection
  final RxSet<int> selectedSessionIds = <int>{}.obs;

  // Submission progress tracking
  final RxInt submissionProgress = 0.obs;
  final RxInt submissionTotal = 0.obs;
  final RxList<String> submissionErrors = <String>[].obs;

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
        filteredBagsList.value = response.output!;
        debugPrint('✅ Loaded ${bagsList.length} bags');
      } else {
        bagsList.value = [];
        filteredBagsList.value = [];
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      _showSnackbar('Error', errorMessage.value, isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  // ─── Selection ───────────────────────────────

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

  // ─── Search ──────────────────────────────────

  void searchBags(String query) {
    searchQuery.value = query;
    filteredBagsList.value = query.isEmpty
        ? bagsList
        : bagsList
            .where((bag) =>
                bag.bagcode.toLowerCase().contains(query.toLowerCase()))
            .toList();
  }

  void clearSearch() {
    searchQuery.value = '';
    filteredBagsList.value = bagsList;
  }

  // ─── Submission ──────────────────────────────

  /// Submit to Lab (type=1). handoverUserId = userId (same person).
  Future<void> submitToLab() async {
    if (!hasSelection) {
      _showSnackbar('Required', 'Please select at least one bag',
          isWarning: true);
      return;
    }

    await _runBatchSubmission(type: 1);
  }

  /// Handover to Connector (type=2). Prompts for connector ID.
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
      final label = type == 1 ? 'Lab' : 'Connector';

      if (submissionErrors.isEmpty) {
        submissionState.value = SubmissionState.success;

        _showSnackbar(
          '✓ Success',
          '$successCount bag(s) submitted to $label successfully',
        );
      } else if (successCount > 0) {
        submissionState.value = SubmissionState.success;
        _showSnackbar(
          '⚠️ Partial Success',
          '$successCount submitted, ${submissionErrors.length} failed',
          isWarning: true,
        );
      } else {
        submissionState.value = SubmissionState.error;
        _showSnackbar(
          '✗ Failed',
          'All submissions failed. Please try again.',
          isError: true,
        );
        submissionState.value = SubmissionState.idle;
      }
      await Future.delayed(const Duration(milliseconds: 300));
      await fetchBags();
    /*  await Future.delayed(const Duration(milliseconds: 800));
      await fetchBags();
      submissionState.value = SubmissionState.idle;*/
    } catch (e) {
      submissionState.value = SubmissionState.error;
      errorMessage.value = e.toString().replaceAll('Exception: ', '');
      _showSnackbar('✗ Error', errorMessage.value, isError: true);
      submissionState.value = SubmissionState.idle;
    }
  }

  void _showSnackbar(
    String title,
    String message, {
    bool isError = false,
    bool isWarning = false,
  }) {
    Color bg = Colors.green.shade100;
    Color text = Colors.green.shade900;
    if (isError) {
      bg = Colors.red.shade100;
      text = Colors.red.shade900;
    } else if (isWarning) {
      bg = Colors.orange.shade100;
      text = Colors.orange.shade900;
    }

    Get.snackbar(
      title,
      message,
      backgroundColor: bg,
      colorText: text,
      snackPosition: SnackPosition.TOP,
      duration: const Duration(seconds: 3),
    );
  }

  void reset() {
    selectedSessionIds.clear();
    errorMessage.value = '';
    submissionState.value = SubmissionState.idle;
    searchQuery.value = '';
    filteredBagsList.value = bagsList;
  }

  //---------- List of handovers -----------------

  final Rxn<Connector> selectedConnector = Rxn<Connector>();
  final RxBool isHandOverToRunnerBoy = false.obs;

  String get currentDesignationId => isHandOverToRunnerBoy.value ? '7' : '151';

// Separate lists and loading flags
  final RxList<Connector> connectorList = <Connector>[].obs;
  final RxList<Connector> runnerBoyList = <Connector>[].obs;
  final RxBool isFetchingConnectors = false.obs;
  final RxBool isFetchingRunnerBoys = false.obs;

// Single entry point when page opens
  void initHandoverPage() {
    selectedConnector.value = null;
    searchQuery.value = '';
    currentHandoverTab.value = 0;
    submissionState.value = SubmissionState.idle;
    submissionErrors.clear();
    // Fetch both in parallel — no jumpToPage here (PageView not mounted yet)
    handoverPageController.jumpToPage(0);
    Future.wait([fetchConnectors(), fetchRunnerBoys()]);
  }

  void resetHandoverPage() {
    connectorList.clear();
    runnerBoyList.clear();
    selectedConnector.value = null;
    searchQuery.value = '';
    submissionState.value = SubmissionState.idle;
    submissionErrors.clear();
  }

  Future<void> fetchConnectors() async {
    try {
      isFetchingConnectors.value = true;
      final list = await bagsService.getConnectorList('151');
      connectorList.value = list;
    } catch (e) {
      _showSnackbar('Error', e.toString(), isError: true);
    } finally {
      isFetchingConnectors.value = false;
    }
  }

  Future<void> fetchRunnerBoys() async {
    try {
      isFetchingRunnerBoys.value = true;
      final list = await bagsService.getConnectorList('7');
      runnerBoyList.value = list;
    } catch (e) {
      _showSnackbar('Error', e.toString(), isError: true);
    } finally {
      isFetchingRunnerBoys.value = false;
    }
  }

// Correct list based on active tab
  List<Connector> get filteredConnectors {
    final source = currentHandoverTab.value == 0 ? connectorList : runnerBoyList;
    if (searchQuery.value.isEmpty) return source;
    final q = searchQuery.value.toLowerCase();
    return source
        .where((c) =>
    c.userName.toLowerCase().contains(q) ||
        c.userId.toString().contains(q))
        .toList();
  }

  bool get isCurrentTabLoading =>
      currentHandoverTab.value == 0
          ? isFetchingConnectors.value
          : isFetchingRunnerBoys.value;

// Tab switch — no re-fetch, data already loaded
  void updateHandoverIndex(int index) {
    currentHandoverTab.value = index;
    isHandOverToRunnerBoy.value = index == 1;
    selectedConnector.value = null; // reset selection when switching tab
    searchQuery.value = '';
  }

  void selectConnector(Connector connector) {
    selectedConnector.value = connector;
  }

  void toggleHandoverType(bool toRunnerBoy) {
    isHandOverToRunnerBoy.value = toRunnerBoy;
    fetchConnectors();
  }

  // Inside CollectedBagsController
  final PageController handoverPageController = PageController();
  final RxInt currentHandoverTab = 0.obs; // 0 for Connector, 1 for Runner Boy

  void switchTab(int index) {
    handoverPageController.animateToPage(index,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }
}
