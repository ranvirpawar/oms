import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../../componenents/otp_boxes_input.dart';
import '../../../../../theme/app_colors.dart';
import '../../../../../utils/helper_functions/helper_methods.dart';
import '../../../../../utils/ui_designs/liquid_snackbar.dart';
import '../../model/patient_queue_model.dart';

class RescheduleSheet extends StatefulWidget {
  final AssignedPatient patient;

  /// Loads the available time slots for a picked date — wired to the
  /// controller's `user/available-slots` call.
  final Future<List<AvailableSlot>> Function(DateTime date) onFetchSlots;

  /// Loads the selectable reschedule reasons — wired to the controller's
  /// `GetRescheduleReasone` call.
  final Future<List<RescheduleReason>> Function() onFetchReasons;

  /// Persists the reschedule. Returns `true` so the sheet can close on success.
  final Future<bool> Function(
      DateTime date, AvailableSlot slot, int rescheduleReasonId) onConfirm;

  /// Sends an OTP to the patient's mobile for reschedule verification.
  final Future<bool> Function(String mobileNo, int orderId) onSendOtp;

  /// Verifies the OTP entered by the phlebotomist.
  final Future<bool> Function(String mobileNo, String otp, int orderId) onVerifyOtp;

  const RescheduleSheet({
    super.key,
    required this.patient,
    required this.onFetchSlots,
    required this.onFetchReasons,
    required this.onConfirm,
    required this.onSendOtp,
    required this.onVerifyOtp,
  });

  /// Convenience launcher — call this from PatientCard's onReschedule or order actions.
  static Future<void> show(
    BuildContext context, {
    required AssignedPatient patient,
    required Future<List<AvailableSlot>> Function(DateTime) onFetchSlots,
    required Future<List<RescheduleReason>> Function() onFetchReasons,
    required Future<bool> Function(DateTime, AvailableSlot, int) onConfirm,
    required Future<bool> Function(String mobileNo, int orderId) onSendOtp,
    required Future<bool> Function(String mobileNo, String otp, int orderId) onVerifyOtp,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => RescheduleSheet(
        patient: patient,
        onFetchSlots: onFetchSlots,
        onFetchReasons: onFetchReasons,
        onConfirm: onConfirm,
        onSendOtp: onSendOtp,
        onVerifyOtp: onVerifyOtp,
      ),
    );
  }

  @override
  State<RescheduleSheet> createState() => _RescheduleSheetState();
}

class _RescheduleSheetState extends State<RescheduleSheet> {
  late final List<DateTime> _dates;

  List<AvailableSlot> _slots = const <AvailableSlot>[];
  List<RescheduleReason> _reasons = const <RescheduleReason>[];

  DateTime? _selectedDate;
  AvailableSlot? _selectedSlot;
  RescheduleReason? _selectedReason;

  bool _loadingSlots = false;
  bool _loadingReasons = false;
  bool _reasonExpanded = false;
  bool _submitting = false;
  String? _slotsError;

  // OTP Verification state
  bool _otpRequired = false;
  bool _otpSending = false;
  bool _otpSent = false;
  bool _otpVerifying = false;
  bool _otpVerified = false;
  String _otpError = '';
  String _enteredOtp = '';
  int _resendCountdown = 0;
  Timer? _resendTimer;
  final GlobalKey<OtpBoxesInputState> _otpKey = GlobalKey<OtpBoxesInputState>();

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _dates = List.generate(
      7,
      (i) => DateTime(today.year, today.month, today.day + i),
    );
    _selectedDate = _dates.first;
    _loadSlots(_dates.first);
    _loadReasons();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    super.dispose();
  }

  bool get _canConfirm =>
      _selectedDate != null &&
      _selectedSlot != null &&
      _selectedReason != null &&
      !_loadingSlots &&
      !_loadingReasons &&
      !_submitting &&
      (!_otpRequired || _otpVerified);

  void _selectDate(DateTime date) {
    if (_selectedDate != null &&
        _selectedDate!.year == date.year &&
        _selectedDate!.month == date.month &&
        _selectedDate!.day == date.day) {
      return;
    }
    setState(() => _selectedDate = date);
    _loadSlots(date);
  }

  Future<void> _loadSlots(DateTime date) async {
    setState(() {
      _selectedSlot = null;
      _loadingSlots = true;
      _slotsError = null;
    });
    try {
      final slots = await widget.onFetchSlots(date);
      if (!mounted) return;
      setState(() {
        _slots = slots;
        _loadingSlots = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _slots = const <AvailableSlot>[];
        _loadingSlots = false;
        _slotsError =
            'We could not load the slots for this date. Choose another date or try again.';
      });
    }
  }

  Future<void> _loadReasons() async {
    setState(() {
      _loadingReasons = true;
      _reasons = const <RescheduleReason>[];
    });
    try {
      final reasons = await widget.onFetchReasons();
      if (!mounted) return;
      setState(() {
        _reasons = reasons;
        _loadingReasons = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _reasons = const <RescheduleReason>[];
        _loadingReasons = false;
      });
    }
  }

  void _selectReason(RescheduleReason reason) {
    setState(() {
      _selectedReason = reason;
      _reasonExpanded = false;
      final required = reason.isOtpRequired;
      if (_otpRequired != required || !_otpVerified) {
        _otpRequired = required;
        _otpSent = false;
        _otpVerified = false;
        _otpSending = false;
        _otpVerifying = false;
        _otpError = '';
        _enteredOtp = '';
        _resendTimer?.cancel();
        _resendCountdown = 0;
      }
    });
  }

  void _startResendTimer() {
    _resendCountdown = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCountdown > 1) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
        setState(() => _resendCountdown = 0);
      }
    });
  }

  Future<void> _handleSendOtp({bool isResend = false}) async {
    final phone = widget.patient.phone ?? '';
    final orderId = widget.patient.sampleCollectionOrderId;

    if (phone.isEmpty) {
      setState(() => _otpError = 'Patient phone number is missing.');
      return;
    }

    setState(() {
      _otpSending = true;
      _otpError = '';
    });

    try {
      final ok = await widget.onSendOtp(phone, orderId);
      if (!mounted) return;
      if (ok) {
        setState(() {
          _otpSent = true;
          _otpSending = false;
          _otpError = '';
          _enteredOtp = '';
        });
        _otpKey.currentState?.clear();
        _startResendTimer();
        LiquidSnack.success(
          isResend ? 'OTP re-sent to patient' : 'OTP sent to patient mobile',
          position: SnackPosition.top
        );
      } else {
        setState(() {
          _otpSending = false;
          _otpError = 'Failed to send OTP. Please try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _otpSending = false;
        _otpError = e
            .toString()
            .replaceAll('Exception: ', '')
            .replaceAll('PatientQueueException: ', '');
      });
    }
  }

  Future<void> _handleVerifyOtp() async {
    if (_enteredOtp.length < 4 || _otpVerifying) return;

    final phone = widget.patient.phone ?? '';
    final orderId = widget.patient.sampleCollectionOrderId;

    setState(() {
      _otpVerifying = true;
      _otpError = '';
    });

    try {
      final ok = await widget.onVerifyOtp(phone, _enteredOtp, orderId);
      if (!mounted) return;
      if (ok) {
        setState(() {
          _otpVerified = true;
          _otpVerifying = false;
          _otpError = '';
        });
        _resendTimer?.cancel();
        LiquidSnack.success('OTP verified successfully', position: SnackPosition.top);
      } else {
        setState(() {
          _otpVerifying = false;
          _otpError = 'Invalid OTP. Please check and re-enter.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _otpVerifying = false;
        _otpError = e
            .toString()
            .replaceAll('Exception: ', '')
            .replaceAll('PatientQueueException: ', '');
      });
    }
  }

  Future<void> _handleConfirm() async {
    if (!_canConfirm) return;
    setState(() => _submitting = true);
    try {
      final ok = await widget.onConfirm(
        _selectedDate!,
        _selectedSlot!,
        _selectedReason!.id,
      );
      if (ok && mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [

                _buildHeader(),
                const Divider(height: 1),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                    children: [
                      _buildPatientSummary(),
                      const SizedBox(height: 10),
                      _buildWarningBanner(),
                      const SizedBox(height: 20),
                      _sectionTitle('Select new date'),
                      const SizedBox(height: 10),
                      _buildDateStrip(),
                      const SizedBox(height: 20),
                      _sectionTitle('Select time slot'),
                      const SizedBox(height: 10),
                      _buildSlotGrid(),
                      const SizedBox(height: 20),
                      _buildReasonSection(),
                      _buildOtpSection(),
                    ],
                  ),
                ),
                _buildConfirmBar(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDragHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 12, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Reschedule Sample Collection',
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.textQuaternary),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientSummary() {
    final p = widget.patient;
    final slotText = p.slotDateTime != null
        ? DateFormat('dd MMM yyyy, hh:mm a').format(p.slotDateTime!)
        : 'Not scheduled';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.bgCardAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      size: 13,
                      color: AppColors.purple,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Current: $slotText',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warningContainer.withOpacity(0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.18)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.warning,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Please inform the coordinator before re-scheduling if fasting or eligibility requirements are not met.',
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13.5,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
  );

  Widget _buildDateStrip() {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _dates.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final date = _dates[index];
          final isSelected = _selectedDate != null &&
              _selectedDate!.year == date.year &&
              _selectedDate!.month == date.month &&
              _selectedDate!.day == date.day;

          return _DateChip(
            date: date,
            isSelected: isSelected,
            onTap: () => _selectDate(date),
          );
        },
      ),
    );
  }

  Widget _buildSlotGrid() {
    if (_loadingSlots) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }

    if (_slotsError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.amberLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.amberBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _slotsError!,
              style: const TextStyle(fontSize: 11.5, height: 1.4),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _selectedDate == null
                  ? null
                  : () => _loadSlots(_selectedDate!),
              icon: const Icon(Icons.refresh_rounded, size: 15),
              label: const Text('Try again', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      );
    }

    if (_slots.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgCardAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.event_busy_rounded,
              size: 16,
              color: AppColors.textTertiary,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'No slots available for this date. Please pick another date.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _slots.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (context, index) {
        final slot = _slots[index];
        final isSelected = _selectedSlot?.slotId == slot.slotId;

        return InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedSlot = slot);
          },
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.accentGradient : null,
              color: isSelected ? null : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? Colors.transparent : AppColors.border,
                width: 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.24),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                slot.timeSlot,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  height: 1,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReasonSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Reason for reschedule'),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _loadingReasons || _reasons.isEmpty
              ? null
              : () => setState(() => _reasonExpanded = !_reasonExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _reasonExpanded ? AppColors.primary600 : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _loadingReasons
                      ? const Text(
                          'Loading reasons...',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textTertiary,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : Text(
                          _selectedReason?.reason ?? 'Select a reason',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _selectedReason != null
                                ? AppColors.textPrimary
                                : AppColors.textTertiary,
                          ),
                        ),
                ),
                if (_loadingReasons)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 180),
                    turns: _reasonExpanded ? 0.5 : 0,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (!_loadingReasons && _reasons.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 14, color: AppColors.textTertiary),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Could not load reasons. Please try again.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary),
                  ),
                ),
              ],
            ),
          ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: _reasonExpanded && _reasons.isNotEmpty
              ? Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _reasons.map((reason) {
                      final isSelected = _selectedReason?.id == reason.id;
                      final isLast = reason == _reasons.last;
                      return InkWell(
                        onTap: () => _selectReason(reason),
                        borderRadius: BorderRadius.vertical(
                          top: reason == _reasons.first ? const Radius.circular(12) : Radius.zero,
                          bottom: isLast ? const Radius.circular(12) : Radius.zero,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            border: isLast
                                ? null
                                : const Border(bottom: BorderSide(color: AppColors.border)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        reason.reason,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          color: isSelected
                                              ? AppColors.primary700
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  /*  if (reason.isOtpRequired) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary50,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppColors.primary200),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.shield_outlined,
                                              size: 11,
                                              color: AppColors.primary600,
                                            ),
                                            SizedBox(width: 3),
                                            Text(
                                              'OTP Required',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],*/
                                  ],
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.check_rounded, size: 18, color: AppColors.primary700),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildOtpSection() {
    if (!_otpRequired) return const SizedBox.shrink();

    final maskedPhone = HelperMethods.maskMobileMiddle(widget.patient.phone ?? '');

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _otpVerified
              ? AppColors.secondary50.withOpacity(0.5)
              : AppColors.primary50.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _otpVerified ? AppColors.secondary200 : AppColors.primary100,
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _otpVerified
                        ? AppColors.secondary100
                        : AppColors.primary100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _otpVerified
                        ? Icons.verified_rounded
                        : Icons.security_rounded,
                    size: 18,
                    color: _otpVerified
                        ? AppColors.secondary700
                        : AppColors.primary700,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _otpVerified
                            ? 'Patient Verified'
                            : 'Patient OTP Verification',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: _otpVerified
                              ? AppColors.secondary800
                              : AppColors.primary800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _otpVerified
                            ? 'OTP verified. Reschedule can now be confirmed.'
                            : _otpSent
                                ? 'Enter 4-digit OTP sent to $maskedPhone'
                                : 'Required for this reason. OTP will be sent to $maskedPhone',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_otpVerified) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.secondary200),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: AppColors.secondary600,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Patient OTP successfully verified',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary700,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (!_otpSent) ...[
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _otpSending ? null : () => _handleSendOtp(),
                  icon: _otpSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 16),
                  label: Text(
                    _otpSending ? 'Sending OTP...' : 'Send OTP to Patient',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              if (_otpError.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 14,
                      color: AppColors.redText,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _otpError,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.redText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ] else ...[
              Center(
                child: OtpBoxesInput(
                  key: _otpKey,
                  length: 4,
                  enableAutofill: false,
                  autofocus: true,
                  boxWidth: 46,
                  boxHeight: 50,
                  spacing: 12,
                  borderRadius: BorderRadius.circular(10),
                  onChanged: (code) {
                    _enteredOtp = code;
                    if (_otpError.isNotEmpty) {
                      setState(() => _otpError = '');
                    }
                    setState(() {});
                  },
                  onCompleted: (code) {
                    _enteredOtp = code;
                    _handleVerifyOtp();
                  },
                ),
              ),
              if (_otpError.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 14,
                      color: AppColors.redText,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        _otpError,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.redText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 42,
                      child: ElevatedButton(
                        onPressed: (_enteredOtp.length == 4 && !_otpVerifying)
                            ? _handleVerifyOtp
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary600,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.border,
                          disabledForegroundColor: AppColors.textMuted,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: _otpVerifying
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Verify OTP',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: _resendCountdown > 0
                        ? Center(
                            child: Text(
                              'Resend in ${_resendCountdown}s',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : TextButton(
                            onPressed: _otpSending
                                ? null
                                : () => _handleSendOtp(isResend: true),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              minimumSize: const Size(0, 42),
                            ),
                            child: _otpSending
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(strokeWidth: 1.8),
                                  )
                                : const Text(
                                    'Resend OTP',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary600,
                                    ),
                                  ),
                          ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_otpRequired && !_otpVerified && _selectedReason != null) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 13,
                    color: AppColors.textTertiary,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Verify patient OTP to enable confirmation',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: _canConfirm ? AppColors.accentGradient : null,
                color: _canConfirm ? null : AppColors.grayLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _canConfirm ? _handleConfirm : null,
                  child: Center(
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Confirm Reschedule',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _canConfirm ? Colors.white : AppColors.textMuted,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateChip extends StatefulWidget {
  final DateTime date;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateChip({
    required this.date,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_DateChip> createState() => _DateChipState();
}

class _DateChipState extends State<_DateChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: 56,
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.accentGradient : null,
            color: isSelected ? null : AppColors.grayLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.transparent : AppColors.border,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.28),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                DateFormat('EEE').format(widget.date).toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white70 : AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                DateFormat('d').format(widget.date),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Text(
                DateFormat('MMM').format(widget.date),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white70 : AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}