
// controllers/patient_registration_controller.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_registration/bag_status_dashboard/service/bag_registration_service.dart';
import 'package:lifenity_connect/utils/ui_designs/liquid_snackbar.dart' hide SnackPosition;

import '../../../../../constants/bag_process_ids.dart';
import '../../../../../services/user_service.dart';
import '../../../../auth/model/login_response_model.dart';
import '../model/qr_bag_details.dart';
import '../model/qr_bag_session.dart';

// controllers/registrarion_bag_controller.dart


class BagRegistrationController extends GetxController {
  final BagRegistrationService _service = BagRegistrationService();
  final UserService userService = Get.put(UserService());

  final Rx<UserModel?> user = Rx<UserModel?>(null);
  final userId = 0.obs;

  final isLoading = false.obs;
  final errorMessage = ''.obs;

  // ─── Torch (used by ScanBagPage) ─────────────────────────────────────────
  // Kept exactly as original — no change.
  final isTorchOn = false.obs;

  // ─── Multi-bag state (NEW) ────────────────────────────────────────────────
  /// All sessions for this user, open and closed, ordered newest first.
  final RxList<QRBagSession> allSessions = <QRBagSession>[].obs;

  /// Details cache: bagId → QRBagDetails
  final RxMap<int, QRBagDetails> bagDetailsMap = <int, QRBagDetails>{}.obs;

  // ─── New convenience getters ──────────────────────────────────────────────
  /// The one currently-open bag, or null.
  QRBagSession? get activeBag =>
      allSessions.firstWhereOrNull((s) => s.isOpen);

  bool get hasBags => allSessions.isNotEmpty;
  bool get hasOpenBag => activeBag != null;

  bool isBagFull(int bagId) {
    final d = bagDetailsMap[bagId];
    if (d == null) return false;
    return d.patientCount >= d.capacity;
  }

  // =========================================================================
  // BACKWARD-COMPATIBILITY SHIMS
  // Every property below is still referenced by existing child screens
  // (patient registration controller, scan page, etc.).
  // They are now computed from `activeBag` / `bagDetailsMap` so that existing
  // code continues to work without any change.
  // =========================================================================

  /// The currently-open session — mirrors old `currentSession`.
  /// Child screens read:  bagController.currentSession.value?.bagId
  ///                      bagController.currentSession.value?.sessionID
  Rx<QRBagSession?> get currentSession => Rx<QRBagSession?>(activeBag);

  /// True only when a bag is open — mirrors old `isBagOpen`.
  /// Child screens read:  bagController.isBagOpen.value
  RxBool get isBagOpen => (activeBag != null).obs;

  /// True when a bag exists but is closed — mirrors old `isBagClosed`.
  /// Child screens read:  bagController.isBagClosed.value
  RxBool get isBagClosed =>
      (allSessions.isNotEmpty && activeBag == null).obs;

  /// The open bag's details — mirrors old `bagDetails`.
  /// Child screens that read bagController.bagDetails.value still work.
  Rxn<QRBagDetails> get bagDetails {
    final bag = activeBag;
    if (bag == null) return Rxn<QRBagDetails>();
    return Rxn<QRBagDetails>(bagDetailsMap[bag.bagId]);
  }

  /// Safe accessors used by child screens that call activeBagId / activeSessionId
  int get activeBagId => activeBag?.bagId ?? 0;
  int get activeSessionId => activeBag?.sessionID ?? 0;
  String get activeBagcode => activeBag?.bagcode ?? '';

  // =========================================================================
  // LIFECYCLE
  // =========================================================================

  @override
  void onInit() {
    super.onInit();
    _loadUser();
  }

  Future<void>? _loadUserFuture;

  /// Loads the current user and their bag session exactly once per controller
  /// lifetime. Memoized so concurrent flows (bag dashboard + sample
  /// collection) never trigger duplicate user/session fetches.
  Future<void> _loadUser() {
    return _loadUserFuture ??= _doLoadUser();
  }

  Future<void> _doLoadUser() async {
    try {
      final userData = await userService.getUser();
      if (userData != null) {
        user.value = userData;
        userId.value = user.value?.empCode ?? 0;
        await checkBagSession();
      }
    } catch (e) {
      debugPrint('❌ Error loading user: $e');
    }
  }

  /// Makes sure user + session data are ready for the current flow. Safe to
  /// call any time: existing sessions are kept, and open-bag details are
  /// refreshed so capacity shown in child flows (e.g. sample collection) is
  /// current.
  Future<void> ensureSessionsLoaded() async {
    await _loadUser(); // memoized — no-op once user/session is loaded

    // Top-up open-bag details so capacity/quota figures are fresh.
    if (allSessions.isEmpty) {
      await checkBagSession(showFeedback: false);
    } else {
      final openSessions = allSessions.where((s) => s.isOpen).toList();
      if (openSessions.isNotEmpty) {
        await Future.wait(openSessions.map(_loadBagDetails));
      }
    }
  }

  Future<void> ensureBagDetailsLoaded(int bagId) async {
    if (bagDetailsMap.containsKey(bagId)) return; // already cached
    final session = allSessions.firstWhereOrNull((s) => s.bagId == bagId);
    if (session == null) return;
    await _loadBagDetails(session);
  }
  // =========================================================================
  // API 1 — GetUserwiseQRBagSession
  // Loads ALL sessions (open + closed) for this user.
  // =========================================================================

  Future<void> checkBagSession({bool showFeedback = true}) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final response = await _service.getUserwiseQRBagSession(userId.value);
      final output = response['output'];

      if (response['status'] == 'Success' &&
          output != null &&
          (output as List).isNotEmpty) {
        final sessions = output
            .map((j) => QRBagSession.fromJson(j))
            .toList()
            .cast<QRBagSession>();
        allSessions.assignAll(sessions);

        // Load details for all open bags in parallel
        final openSessions = sessions.where((s) => s.isOpen).toList();
        await Future.wait(openSessions.map(_loadBagDetails));
      } else {
        allSessions.clear();
        bagDetailsMap.clear();
      }
    } catch (e) {
      errorMessage.value = e.toString();
      if (showFeedback) {
        Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
      }
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================================
  // API 2 — Proc_GetQRBagDetails  (internal helper)
  // =========================================================================

  Future<void> _loadBagDetails(QRBagSession session) async {
    try {
      final response = await _service.getQRBagDetails(
        sessionId: session.sessionID,
        bagId: session.bagId,
      );

      final output = response['output'];
      if (response['status'] == 'Success' &&
          output != null &&
          (output as List).isNotEmpty) {
        bagDetailsMap[session.bagId] = QRBagDetails.fromJson(output.first);
      }
    } catch (e) {
      debugPrint('❌ Error loading bag details for bag ${session.bagId}: $e');
    }
  }

  // =========================================================================
  // API 3 — InsertStartQRCodeBagEvent  →  Open a brand-new bag  (processId = 2)
  // Called from ScanBagPage after scanning a barcode.
  // If another bag is already open it is auto-closed first (CR rule).
  // =========================================================================

  Future<bool> openBag(String scannedBagcode) async {
    try {
      isLoading.value = true;

      // Auto-close the currently open bag (only one allowed open at a time)
      if (hasOpenBag) {
        final closed = await _closeBagSilently(activeBag!);
        if (!closed) {
          Get.snackbar(
            'Failed',
            'Could not close the existing open bag. Please try again.',
            snackPosition: SnackPosition.BOTTOM,
          );
          return false;
        }
      }

      final response = await _service.insertStartQRCodeBagEvent(
        bagcode: scannedBagcode,
        processId: int.parse(BagProcessId.bagOpenedByPhlebotomist.processId),
        facilityCode: '0',
        userId: userId.value,
      );

      if (response['status'] == 'Success') {
        final output = (response['output'] as Map<String, dynamic>?) ?? {};

        final newSession = QRBagSession(
          sessionID: output['Sessionid'] ?? 0,
          bagId: output['S_bagid'] ?? 0,
          bagcode: scannedBagcode,
          bagCloseStatus: 0,
        );

        // Insert at the top so it appears first in the dashboard list
        allSessions.insert(0, newSession);
        await _loadBagDetails(newSession);

        LiquidSnack.success( 'Bag opened successfully!',
            );
        return true;
      }

      Get.snackbar('Failed', response['message'] ?? 'Could not open bag',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================================
  // Internal — close a bag silently (no snackbar), used during auto-close
  // =========================================================================

  Future<bool> _closeBagSilently(QRBagSession session) async {
    try {
      final response = await _service.insertQRBagSessionEvent(
        sessionId: session.sessionID,
        processId: 3,
        userId: userId.value,
      );

      if (response['status'] == 'Success') {
        _updateSessionStatus(session, 1);
        bagDetailsMap.remove(session.bagId);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Silent close failed: $e');
      return false;
    }
  }

  // =========================================================================
  // API 4a — InsertQRBagSession_Event  →  Close bag  (processId = 3)
  // Accepts a specific session so the dashboard can close any bag by card.
  // Also exposed as a no-arg variant for child screens that call
  //   bagController.closeBag()   (old signature — closes the active bag).
  // =========================================================================

  /// Close a specific bag by session object (called from dashboard card).
  Future<void> closeBag(QRBagSession session) async {
    try {
      isLoading.value = true;

      final response = await _service.insertQRBagSessionEvent(
        sessionId: session.sessionID,
        processId: 3,
        userId: userId.value,
      );

      if (response['status'] == 'Success') {
        _updateSessionStatus(session, 1);
        bagDetailsMap.remove(session.bagId);
        Get.snackbar('Success', 'Bag closed successfully!',
            snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar('Failed', response['message'] ?? 'Could not close bag',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  /// Close the currently-open bag (no-arg shim for old child-screen callers).
  Future<void> closeActiveBag() async {
    if (activeBag != null) await closeBag(activeBag!);
  }

  // =========================================================================
  // API 4b — InsertQRBagSession_Event  →  Reopen bag  (processId = 2)
  // Auto-closes any other open bag first.
  // =========================================================================

  Future<void> reopenBag(QRBagSession session) async {
    try {
      isLoading.value = true;

      // Auto-close the currently open bag if it is a different one
      if (hasOpenBag && activeBag!.bagId != session.bagId) {
        final closed = await _closeBagSilently(activeBag!);
        if (!closed) {
          Get.snackbar(
            'Failed',
            'Could not close the existing open bag. Please try again.',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
      }

      final response = await _service.insertQRBagSessionEvent(
        sessionId: session.sessionID,
        processId: 2,
        userId: userId.value,
      );

      if (response['status'] == 'Success') {
        _updateSessionStatus(session, 0);
        await _loadBagDetails(
          allSessions.firstWhere((s) => s.sessionID == session.sessionID),
        );
        LiquidSnack.success('Bag reopened successfully!'
           );
      } else {
        Get.snackbar('Failed', response['message'] ?? 'Could not reopen bag',
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      Get.snackbar('Error', e.toString(), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  // =========================================================================
  // Helper — mutate a session's BagCloseStatus in-place inside allSessions
  // =========================================================================

  void _updateSessionStatus(QRBagSession session, int closeStatus) {
    final idx =
    allSessions.indexWhere((s) => s.sessionID == session.sessionID);
    if (idx != -1) {
      allSessions[idx] = QRBagSession(
        sessionID: session.sessionID,
        bagId: session.bagId,
        bagcode: session.bagcode,
        bagCloseStatus: closeStatus,
      );
    }
  }

  Future<void> refreshDashboard() async => await checkBagSession();
}
