import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../constants/app_assets.dart';
import '../../../../../theme/app_colors.dart';
import '../../controller/patient_report_controller.dart';
import '../../model/patiet_report_data.dart';
import 'package:get/get.dart' hide SnackPosition;

import 'package:flutter_svg/flutter_svg.dart';

import '../../../../../utils/ui_designs/liquid_snackbar.dart';

enum ConsentState { idle, loading, granted, notGranted }

class WhatsAppShareSheet extends StatefulWidget {
  final PatientReportData report;

  const WhatsAppShareSheet({super.key, required this.report});

  @override
  State<WhatsAppShareSheet> createState() => _WhatsAppShareSheetState();
}

class _WhatsAppShareSheetState extends State<WhatsAppShareSheet> {
  late TextEditingController _mobileController;
  final PatientReportController _controller = Get.find();

  bool _useDefaultNumber = true;
  ConsentState _consentState = ConsentState.loading;

  // Debounce timer for custom number input
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _mobileController = TextEditingController(text: widget.report.mobile);
    // Fire consent check immediately for the default number
    _fetchConsentFor(widget.report.mobile);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _fetchConsentFor(String mobile) async {
    if (mobile.length != 10) return;

    setState(() => _consentState = ConsentState.loading);

    final status = await _controller.fetchConsentStatus(mobile);

    if (!mounted) return;
    setState(() {
      _consentState = status == 'YES'
          ? ConsentState.granted
          : ConsentState.notGranted;
    });
  }

  void _onCustomNumberChanged(String value) {
    _debounce?.cancel();

    if (value.length == 10) {
      // Show loading immediately when we're about to call the API
      setState(() => _consentState = ConsentState.loading);
      _debounce = Timer(const Duration(milliseconds: 500), () {
        _fetchConsentFor(value);
      });
    } else {
      // User is still typing — no API pending, no opinion yet
      setState(() => _consentState = ConsentState.idle);
    }
  }

  String get _activeNumber => _mobileController.text;

  bool get _canSendReport =>
      _consentState == ConsentState.granted && _activeNumber.length == 10;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // _buildHandle(),
              _buildHeader(),
              _buildReportDetailsCard(),
              const SizedBox(height: 20),
              _buildNumberSelector(),
              const SizedBox(height: 16),
              _buildConsentBanner(),
              const SizedBox(height: 20),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Handle bar ───────────────────────────────────────────────────────────

  Widget _buildHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.emerald700.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SvgPicture.asset(
              AppAssets.whatsAppIcon,
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                AppColors.emerald700,
                BlendMode.srcIn,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send report via WhatsApp',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  'Share lab results securely',
                  style: TextStyle(fontSize: 12, color: Color(0xFF757575)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, size: 22),
            color: Colors.grey[600],
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ─── Report details card ──────────────────────────────────────────────────

  Widget _buildReportDetailsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        children: [
          _buildDetailRow(Icons.qr_code_rounded, 'Barcode', widget.report.barcode),
          const Divider(height: 20),
          _buildDetailRow(
            Icons.person_outline_rounded,
            'Patient',
            widget.report.patientName ?? 'N/A',
          ),
          const Divider(height: 20),
          _buildDetailRow(Icons.phone_android_rounded, 'Registered mobile', widget.report.mobile),
        ],
      ),
    );
  }

  // ─── Number selector ──────────────────────────────────────────────────────

  Widget _buildNumberSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Send to',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 10),
          _buildNumberOption(
            selected: _useDefaultNumber,
            title: "Patient's registered number",
            subtitle: widget.report.mobile,
            onTap: () {
              if (_useDefaultNumber) return; // already selected
              setState(() {
                _useDefaultNumber = true;
                _mobileController.text = widget.report.mobile;
                _consentState = ConsentState.loading;
              });
              _fetchConsentFor(widget.report.mobile);
            },
          ),
          const SizedBox(height: 10),
          _buildNumberOption(
            selected: !_useDefaultNumber,
            title: 'Different number',
            subtitle: 'Send to a caregiver or alternate contact',
            onTap: () {
              if (!_useDefaultNumber) return;
              setState(() {
                _useDefaultNumber = false;
                _mobileController.clear();
                _consentState = ConsentState.idle; // ← was: loading
              });
            },
          ),
          if (!_useDefaultNumber) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              onChanged: _onCustomNumberChanged,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.phone_outlined,
                  color: AppColors.emerald700,
                  size: 20,
                ),
                hintText: '10-digit mobile number',
                hintStyle: const TextStyle(fontSize: 14),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide(color: AppColors.emerald700, width: 1.5),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNumberOption({
    required bool selected,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.emerald700.withOpacity(0.08) : Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.emerald700 : Colors.grey[300]!,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: selected ? AppColors.emerald700 : Colors.grey[400],
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Consent banner ───────────────────────────────────────────────────────
  // This is the KEY UX piece — it tells the user exactly what's happening

  Widget _buildConsentBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _consentBannerContent(),
      ),
    );
  }

  Widget _consentBannerContent() {
    switch (_consentState) {
      case ConsentState.idle:
        return const SizedBox.shrink(key: ValueKey('idle'));
      case ConsentState.loading:
        return _buildBanner(
          key: const ValueKey('loading'),
          icon: Icons.hourglass_top_rounded,
          iconColor: Colors.grey[500]!,
          bgColor: Colors.grey[100]!,
          borderColor: Colors.grey[300]!,
          title: 'Checking consent status…',
          subtitle: 'Please wait while we verify.',
        );

      case ConsentState.notGranted:
        return _buildBanner(
          key: const ValueKey('no-consent'),
          icon: Icons.info_outline_rounded,
          iconColor: const Color(0xFFB45309),
          bgColor: const Color(0xFFFFFBEB),
          borderColor: const Color(0xFFFCD34D),
          title: 'Consent required before sending',
          subtitle:
          'This patient hasn\'t agreed to receive lab reports on WhatsApp. '
              'Send a consent request first — once they approve, you\'ll be able to share reports.',
        );

      case ConsentState.granted:
        return _buildBanner(
          key: const ValueKey('consent-ok'),
          icon: Icons.verified_rounded,
          iconColor: AppColors.emerald700,
          bgColor: AppColors.emerald700.withOpacity(0.06),
          borderColor: AppColors.emerald700.withOpacity(0.3),
          title: 'Consent confirmed — ready to send',
          subtitle:
          'This number has consented to receive lab reports via WhatsApp.',
        );
    }
  }

  Widget _buildBanner({
    required Key key,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Action buttons ───────────────────────────────────────────────────────

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Row(
        children: [
          // Send consent — only visible when consent is NOT granted
          if (_consentState == ConsentState.notGranted) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: _onSendConsentTapped,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: BorderSide(color: Colors.green.shade300),
                ),
                child: const Text(
                  'Request consent',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4A9C6E),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],

          // Send report
          Expanded(
            flex: _consentState == ConsentState.notGranted ? 1 : 2,
            child: ElevatedButton.icon(
              onPressed: _canSendReport ? _onSendReportTapped : null,
              icon: const Icon(Icons.send_rounded, size: 16),
              label: const Text(
                'Send report',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                _canSendReport ? AppColors.emerald700 : Colors.grey[300],
                foregroundColor:
                _canSendReport ? Colors.white : Colors.grey[500],
                disabledBackgroundColor: Colors.grey[300],
                disabledForegroundColor: Colors.grey[500],
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  void _onSendConsentTapped() {
    final number = _activeNumber;
    if (number.length != 10) {
      LiquidSnack.warning('Enter a valid 10-digit mobile number');
      return;
    }
    _controller.sendConsent(number);
    Navigator.pop(context); // Close sheet after requesting consent
  }

  void _onSendReportTapped() {
    Navigator.pop(context, {
      'send': true,
      'mobile': _activeNumber,
    });
  }

  // ─── Detail row ───────────────────────────────────────────────────────────

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary.withOpacity(0.7)),
        const SizedBox(width: 10),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Flexible(
                child: SelectableText(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
