// order_confirmation_controller.dart
//
// Owns everything on the Order Confirmation flow: loading the order,
// route/GPS tracking on the way to the patient, the bag-open gate, and OTP
// verification. Created fresh by OrderConfirmationBinding every time a
// phlebotomist opens a patient from the queue, and torn down (onClose runs,
// timers/streams cancelled) when that route is popped — so nothing here can
// leak into the next patient.
//
// Deliberately does NOT own sample entries, complications, or incomplete
// reasons — those belong to SampleCollectionController because they're only
// ever rendered on that screen. Fetching them here (as the old combined
// controller did) meant wasted API calls on every order confirmation, even
// when the phlebotomist never reached the collection step.

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../../../../componenents/otp_boxes_input.dart';
import '../../../../routes/route_manager.dart';
import '../../../../services/auth_manager.dart';
import '../../patient_queue/service/location_tracking_service.dart';
import '../../../../utils/helper_functions/helper_methods.dart';
import '../../../../utils/ui_designs/liquid_snackbar.dart' hide SnackPosition;
import '../../patient_queue/model/patient_queue_model.dart';
import '../../patient_queue/service/patient_queue_service.dart';
import '../binding/sample_collection_binding.dart';
import '../model/pre_collection_checklist.dart';
import '../model/sample_collection_models.dart';
import '../service/sample_collection_service.dart';
import '../view/collection_checklist_screen.dart';
import '../view/sample_collection_screen.dart';
import '../view/widgets/otp_verification_screen.dart';
import 'bag_context_mixin.dart';

import 'sample_collection_controller.dart';

class OrderConfirmationController extends GetxController with HasBagContext {
  OrderConfirmationController({required this.assignedPatient})
      : orderId = assignedPatient.orderId.toString();
  final PatientQueueService _patientQueueService = PatientQueueService();
  final AssignedPatient assignedPatient;
  final String orderId;

  final SampleCollectionService _service = SampleCollectionService();
  final AuthManager _authManager = AuthManager();
  final LocationTrackingService _locationTrackingService =
      LocationTrackingService();

  final RxString empId = ''.obs;
  final RxBool isRescheduling = false.obs;
  int get _userId => int.tryParse(empId.value) ?? 0;

  bool get isOrderAccepted =>
      assignedPatient.status == PatientStatus.accepted ||
      assignedPatient.status == PatientStatus.rescheduled ||
      assignedPatient.status == PatientStatus.inRoute ||
      assignedPatient.status == PatientStatus.arrived;

  bool get needsToStartRoute =>
      assignedPatient.status == PatientStatus.accepted || assignedPatient.status == PatientStatus.rescheduled;

  // ---- Order details -------------------------------------------------
  final Rxn<OrderConfirmationDetails> orderDetails =
      Rxn<OrderConfirmationDetails>();
  final RxBool isLoadingOrder = false.obs;
  final RxString orderLoadError = ''.obs;

  String get maskedPatientMobileNumber =>
      HelperMethods.maskMobileMiddle(orderDetails.value?.mobileNumber ?? '');

  // ---- Route / GPS tracking -------------------------------------------
  final RxBool showRouteMap = false.obs;
  final RxBool isMarkingArrived = false.obs;
  final Rx<Position?> currentPosition = Rx<Position?>(null);
  StreamSubscription<Position>? _positionSub;
  double? _initialDistanceMeters;

  double? get destinationLat => assignedPatient.destinationLat;
  double? get destinationLng => assignedPatient.destinationLng;

  double? get distanceToPatientMeters {
    final lat = destinationLat;
    final lng = destinationLng;
    final pos = currentPosition.value;
    if (lat == null || lng == null || pos == null) return null;
    return Geolocator.distanceBetween(pos.latitude, pos.longitude, lat, lng);
  }

  double get routeProgress {
    final current = distanceToPatientMeters;
    if (current == null) return 0;
    _initialDistanceMeters ??= current;
    final initial = _initialDistanceMeters!;
    if (initial <= 0) return 1;
    return (1 - (current / initial)).clamp(0.0, 1.0);
  }

  // ---- OTP ---------------------------------------------------------------
  final GlobalKey<OtpBoxesInputState> otpInputKey =
      GlobalKey<OtpBoxesInputState>();
  String get otpValue => otpInputKey.currentState?.code ?? '';

  final RxBool isSendingOtp = false.obs;
  final RxBool isVerifyingOtp = false.obs;
  final RxString otpError = ''.obs;
  final RxInt resendSecondsLeft = 0.obs;
  Timer? _resendTimer;

  /// Set only for the lifetime of a single OTP-screen visit. Read by
  /// [confirmAndCollect] right after that screen is popped, to tell apart
  /// "OTP verified successfully" from "phlebotomist just backed out".
  bool _otpVerifiedThisSession = false;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  @override
  void onClose() {
    _resendTimer?.cancel();
    _positionSub?.cancel();
    super.onClose();
  }

  Future<void> _init() async {
    await _loadEmpId();
    if (!isOrderAccepted) return;
    if (needsToStartRoute) return;

    if (assignedPatient.status == PatientStatus.inRoute) {
      showRouteMap.value = true;
      _startLocationUpdates();
      return;
    }

    await Future.wait([
      fetchOrderDetails(),
      bagController.ensureSessionsLoaded(),
    ]);
  }

  Future<void> _loadEmpId() async {
    try {
      final data = await _authManager.getUserData();
      if (data != null) {
        final user = data['user'];
        if (user != null && user.containsKey('EmpCode')) {
          empId.value = user['EmpCode'].toString();
          kPrint(empId.value);
        }
      }
    } catch (_) {
      // Non-fatal — later calls send an empty/derived userId; backend can
      // reject if it's required and missing.
    }
  }

  // ---------------------------------------------------------------------
  // Route / GPS
  // ---------------------------------------------------------------------

  void _startLocationUpdates() {
    _positionSub?.cancel();
    _resolveInitialPosition();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) => currentPosition.value = pos);
  }

  Future<void> _resolveInitialPosition() async {
    try {
      currentPosition.value = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      // Ignored — the stream will deliver a fix when one becomes available.
    }
  }

  /// END tracking ping — flips the order out of "En Route", stops the GPS
  /// stream and loads the collection details for the arrived visit.
  Future<void> markArrived() async {
    if (isMarkingArrived.value) return;
    isMarkingArrived.value = true;
    try {
      final pos = currentPosition.value ??
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
      final success = await _locationTrackingService.sendTracking(
        orderAssignDetailId: assignedPatient.orderAssignDetailId ?? 0,
        sampleCollectionOrderId: assignedPatient.sampleCollectionOrderId,
        userId: _userId,
        action: TrackingAction.end,
        latitude: pos.latitude,
        longitude: pos.longitude,
        createdBy: _userId,
      );
      if (success) {
        _positionSub?.cancel();
        showRouteMap.value = false;
        await Future.wait([
          fetchOrderDetails(),
          bagController.ensureSessionsLoaded(),
        ]);
      } else {
        LiquidSnack.error(
          'Unable to mark arrival. Please try again.',
          title: 'Action failed',
        );
      }
    } on LocationTrackingException catch (e) {
      LiquidSnack.error(e.message, title: 'Action failed');
    } catch (_) {
      LiquidSnack.error(
        'Please try again.',
        title: 'Action failed',
      );
    } finally {
      isMarkingArrived.value = false;
    }
  }

  // ---------------------------------------------------------------------
  // Order details
  // ---------------------------------------------------------------------

  Future<void> fetchOrderDetails() async {
    isLoadingOrder.value = true;
    orderLoadError.value = '';
    try {
      final details = await _service.fetchOrderDetails(
        orderId: orderId,
        userId: empId.value,
      );
      orderDetails.value = details;
    } on SampleCollectionException catch (e) {
      orderLoadError.value = e.message;
    } catch (e) {
      kPrint(e.toString());
      orderLoadError.value = 'Something went wrong while loading this order.';
    } finally {
      isLoadingOrder.value = false;
    }
  }

  // ---------------------------------------------------------------------
  // OTP
  // ---------------------------------------------------------------------

  Future<void> sendOtp() async {
    isSendingOtp.value = true;
    otpError.value = '';
    try {
      final mobileNumber = orderDetails.value?.mobileNumber ?? '';
      await _service.sendCollectionOtp(
        mobileNumber: mobileNumber,
        userId: empId.value,
        collectionOrderId: orderDetails.value?.sampleCollectionOrderId ?? '',
      );
      LiquidSnack.success('OTP has been send successfully');
      _startResendTimer();
    } catch (e) {
      otpError.value = 'Unable to send OTP. Please try again.';
    } finally {
      isSendingOtp.value = false;
    }
  }

  Future<void> resendOtp() async {
    if (resendSecondsLeft.value > 0) return;
    otpError.value = '';
    otpInputKey.currentState?.clear();
    await sendOtp();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    resendSecondsLeft.value = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendSecondsLeft.value <= 1) {
        timer.cancel();
        resendSecondsLeft.value = 0;
      } else {
        resendSecondsLeft.value--;
      }
    });
  }

  /// Verifies the OTP and, on success, pops the OTP screen itself. Control
  /// then returns to whoever `await`-ed the `Get.to()` that pushed it (see
  /// [confirmAndCollect]) — that's the single place deciding what happens
  /// next, instead of a reactive `ever()` listener registered in build().
  Future<void> verifyOtp() async {
    final otp = otpValue;
    if (otp.length != 4) {
      otpError.value = 'Enter the 4-digit OTP.';
      return;
    }
    isVerifyingOtp.value = true;
    otpError.value = '';
    try {
      final success = await _service.verifyCollectionOtp(
        userId: empId.value,
        otp: otp,
        mobileNumber: orderDetails.value?.mobileNumber ?? '',
        collectionOrderId: orderDetails.value?.sampleCollectionOrderId ?? '',
      );
      if (success) {
        _otpVerifiedThisSession = true;
        Get.back();
      } else {
        otpError.value = 'Incorrect OTP. Please try again.';
      }
    } catch (e) {
      otpError.value = 'Unable to verify OTP. Please try again.';
    } finally {
      isVerifyingOtp.value = false;
    }
  }

  // ---------------------------------------------------------------------
  // Navigation into Sample Collection
  // ---------------------------------------------------------------------

  Future<void> confirmAndCollect() async {
    if (!hasOpenBag) {
      LiquidSnack.error('You need to open a bag first for sample collection');
      return;
    }
    final details = orderDetails.value;
    if (details == null) return;
    kPrint('isOTPVerified ${details.isOtpVerified}');

    // NOTE: preserved verbatim from the original controller — when
    // `isOtpVerified` is explicitly `false`, OTP runs; when it's 'Yes',
    // it's skipped. Kept as-is because behaviour must not change — worth
    // confirming with whoever owns this field that the sense isn't inverted.
    if (details.isOtpVerified != 'Yes') {
      _otpVerifiedThisSession = false;
      await sendOtp();
      await Get.to(() => const OtpVerificationScreen());
      if (!_otpVerifiedThisSession) return; // backed out without verifying
    }

    // final checklistCompleted = await _goToChecklist();
    // if (!checklistCompleted) return; // backed out without completing it

    await _goToSampleCollection();
  }

  /// Loads and pushes the collection checklist. Returns true only if the
  /// phlebotomist submitted it successfully.
  Future<bool> _goToChecklist() async {
    _checklistCompletedThisSession = false;
    await fetchChecklist();
    await Get.to(() => const CollectionChecklistScreen());
    return _checklistCompletedThisSession;
  }

  Future<void> _goToSampleCollection() async {
    // Belt-and-suspenders: GetX will normally dispose the previous instance
    // when its route is popped, but force-deleting here guarantees a fresh
    // controller even if some earlier navigation left one registered.
    if (Get.isRegistered<SampleCollectionController>()) {
      Get.delete<SampleCollectionController>(force: true);
    }

    await Get.to(
      () => const SampleCollectionScreen(),
      binding: SampleCollectionBinding(
        orderId: orderId,
        assignedPatient: assignedPatient,
      ),
      transition: Transition.circularReveal,
      duration: const Duration(milliseconds: 200),
    );

    // We're back on this screen — either the phlebotomist pressed back, or
    // a submission finished and unwound the stack down to here. Either way,
    // refresh so order status / bag capacity are never stale.
    await Future.wait([
      fetchOrderDetails(),
      bagController.checkBagSession(showFeedback: false),
    ]);
  }
  Future<List<RescheduleReason>> fetchRescheduleReasons() {
    return _patientQueueService.fetchRescheduleReasons();
  }

  Future<List<AvailableSlot>> fetchAvailableSlots(DateTime date) {
    return _patientQueueService.fetchAvailableSlots(
      userId: empId.value,
      appointmentDate: date,
    );
  }
  Future<bool> _runAction(
      Future<bool> Function() action, {
        required String successMessage,
      }) async {
    isRescheduling.value = true;
    try {
      final success = await action();
      if (success) {
        LiquidSnack.success(successMessage, title: 'Success');
        await RouteManager.redirectToHomeDashboard();
        RouteManager.navigateToPatientQueue();
      }
      return success;
    } on SampleCollectionException catch (e) {
      LiquidSnack.error(e.message, title: 'Action failed');
      return false;
    } catch (e) {
      LiquidSnack.error(
        'Something went wrong. Please try again.',
        title: 'Action failed',
      );
      return false;
    } finally {
      isRescheduling.value = false;
    }
  }

  Future<bool> reschedule(
      AssignedPatient patient, {
        required DateTime newDate,
        required AvailableSlot slot,
        required int rescheduleReasonId,
      }) {
    return _runAction(
          () => _service.reschedule(
        orderId: patient.orderId,
        userId: _userId,
        createdBy: _userId,
        appointmentDate: newDate,
        slotId: slot.slotId,
        rescheduleReasonId: rescheduleReasonId,
      ),
      successMessage: 'Visit rescheduled',
    );
  }
  @override
  int get requiredSampleCount {
    return orderDetails.value?.totalSampleTypes ?? 0;
  }
  // ---------------------------------------------------------------------
// Collection checklist
// ---------------------------------------------------------------------
  final RxList<ChecklistItem> checklistItems = <ChecklistItem>[].obs;
  final RxBool isLoadingChecklist = false.obs;
  final RxBool isSubmittingChecklist = false.obs;
  final RxString checklistError = ''.obs;

  bool get isChecklistComplete =>
      checklistItems.isNotEmpty &&
          checklistItems.every((item) => item.value.isNotEmpty);

  /// Mirrors [_otpVerifiedThisSession] — set only for the lifetime of a
  /// single checklist-screen visit, read right after it's popped.
  bool _checklistCompletedThisSession = false;

  Future<void> fetchChecklist() async {
    isLoadingChecklist.value = true;
    checklistError.value = '';
    try {
      final items = await _service.fetchCollectionChecklist(
        orderId: orderId,
        userId: empId.value,
      );
      checklistItems.assignAll(items);
    } on SampleCollectionException catch (e) {
      checklistError.value = e.message;
    } catch (e) {
      kPrint(e.toString());
      checklistError.value =
      'Something went wrong while loading the checklist.';
    } finally {
      isLoadingChecklist.value = false;
    }
  }

  void setChecklistAnswer(int checklistId, String value) {
    final index =
    checklistItems.indexWhere((i) => i.checklistId == checklistId);
    if (index == -1) return;
    checklistItems[index].value = value;
    // ChecklistItem is a mutable plain object inside an RxList, so mutating
    // a field in place doesn't trigger a rebuild on its own — nudge it.
    checklistItems.refresh();
  }

  Future<bool> _submitChecklist() async {
    if (!isChecklistComplete) {
      LiquidSnack.error('Please answer every checklist item before continuing');
      return false;
    }
    isSubmittingChecklist.value = true;
    try {
      final answers = checklistItems
          .map((i) => ChecklistAnswer(
        checklistId: i.checklistId,
        checklistValue: i.value,
      ))
          .toList();
      return await _service.submitCollectionChecklist(
        orderId: orderId,
        userId: _userId,
        createdBy: _userId,
        answers: answers,
      );
    } on SampleCollectionException catch (e) {
      LiquidSnack.error(e.message, title: 'Action failed');
      return false;
    } catch (_) {
      LiquidSnack.error(
        'Something went wrong. Please try again.',
        title: 'Action failed',
      );
      return false;
    } finally {
      isSubmittingChecklist.value = false;
    }
  }

  /// Called by the checklist screen's Continue button. Submits, and only
  /// pops back to [confirmAndCollect] on success — a failed submit leaves
  /// the phlebotomist on the checklist screen to fix/retry.
  Future<void> completeChecklist() async {
    final success = await _submitChecklist();
    if (success) {
      _checklistCompletedThisSession = true;
      Get.back();
    }
  }
}
