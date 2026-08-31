import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_report/service/patient_report_service.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_report/view/in_app_report_view.dart';
import 'package:lifenity_connect/services/snackbar_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../services/auth_manager.dart';
import '../../patient_registration/models/center_name_model.dart';
import '../../patient_registration/models/facility_list_model.dart';
import '../../patient_registration/service/patient_registration_service.dart';
import '../model/patiet_report_data.dart';
import '../model/test_status_model.dart';
import '../view/report_details_page.dart';
import '../view/widget/share_to_whatsapp_widget.dart';
import 'in_app_report_view_controller.dart';

class PatientReportController extends GetxController {
  var isLoading = false.obs;
  var initialLoading = false.obs;
  final RxString empId = ''.obs;
  final RxList<CenterModel> labNames = <CenterModel>[].obs;
  final RxList<FacilityModel> facilityNames = <FacilityModel>[].obs;

  final RxString labInfoError = ''.obs;
  final RxString facilityInfoError = ''.obs;
  final RxString consentStatus = ''.obs;

  final Rx<CenterModel?> selectedLabName = Rx<CenterModel?>(null);
  final Rx<FacilityModel?> selectedFacilityName = Rx<FacilityModel?>(null);

  // Date selection
  final Rx<DateTime?> fromDate = Rx<DateTime?>(
    DateTime.now().subtract(const Duration(days: 7)),
  );
  final Rx<DateTime?> toDate = Rx<DateTime?>(DateTime.now());
  final TextEditingController searchController = TextEditingController();

  // Report data
  final RxList<PatientReportData> patientReports = <PatientReportData>[].obs;
  final RxList<PatientReportData> filteredReports = <PatientReportData>[].obs;
  final RxString searchQuery = ''.obs;

  var shareBtnPressed = false.obs;
  final RxMap<String, bool> shareBtnLoadingStates = <String, bool>{}.obs;

  // Services
  final PatientRegistrationService _service = Get.put(
    PatientRegistrationService(),
  );
  final PatientReportService _reportService = Get.put(PatientReportService());
  final AuthManager authManager = Get.find<AuthManager>();
  final ReportPdfViewerController inAppReportViewController = Get.put(
    ReportPdfViewerController(),
  );

  @override
  void onInit() {
    super.onInit();
    getUserdata();
    searchController.addListener(() {
      print("🎯 Search controller text changed: '${searchController.text}'");
      filterReports(searchController.text);
    });
  }

  void getUserdata() {
    authManager
        .getUserData()
        .then((data) {
          print('📅user data from auth');
          if (data != null) {
            data.forEach((key, value) {
              debugPrint('$key: $value');
            });
            final user = data['user'];
            if (user != null && user.containsKey('EmpCode')) {
              empId.value = user['EmpCode'].toString();
              fetchDropdownData();
              debugPrint('✅ empId set: ${empId.value}');
            } else {
              debugPrint('❌ EmpCode not found in user data');
            }
          } else {
            debugPrint('No user data found');
          }
        })
        .catchError((err) {
          debugPrint('Error loading user data: $err');
        });
  }

  void fetchDropdownData() async {
    try {
      isLoading.value = true;
      initialLoading.value = true;
      final userId = empId.value;

      final centers = await _service.getLabNames(userId);
      labNames.assignAll(centers);
      if (labNames.isNotEmpty) {
        selectedLabName.value = labNames.first;
      }

      final facilities = await _service.getFacilityList(userId);
      facilityNames.assignAll(facilities);
      if (facilityNames.isNotEmpty) {
        selectedFacilityName.value = facilityNames.first;
      }
      await fetchPatientReports();
    } catch (e) {
      print('Error loading dropdown data: $e');
    } finally {
      isLoading.value = false;
      initialLoading.value = false;
    }
  }

  Future<void> fetchPatientReports() async {
    // Validation
    if (selectedLabName.value == null) {
      labInfoError.value = 'Please select a lab';
      return;
    }
    if (selectedFacilityName.value == null) {
      facilityInfoError.value = 'Please select a facility';
      return;
    }
    if (fromDate.value == null || toDate.value == null) {
      SnackBarService.to.showMessage(
        message: 'Please select both from and to dates',
      );
      return;
    }

    try {
      isLoading.value = true;
      labInfoError.value = '';
      facilityInfoError.value = '';

      final fromDateStr = DateFormat('yyyy/MM/dd').format(fromDate.value!);
      final toDateStr = DateFormat('yyyy/MM/dd').format(toDate.value!);

      final reports = await _reportService.getPatientReportsList(

       userId:  empId.value,
        fromDate: fromDateStr,
        toDate: toDateStr,
       facilityCode:  selectedFacilityName.value!.facilityId.toString(),
       mobileNumber:  '', // Mobile number empty for now
      );
      reports.sort((a, b) => a.visitDate.compareTo(b.visitDate));
      patientReports.assignAll(reports);
      filteredReports.assignAll(reports);

      if (reports.isEmpty) {
        SnackBarService.to.showMessage(
          message: 'No reports found for the selected date range',
        );
      }
    } catch (e) {
      SnackBarService.to.showMessage(message: 'Failed to fetch reports');
      debugPrint('Error fetching patient reports: $e');
    } finally {
      isLoading.value = false;
    }
  }
// REMOVE this from PatientReportController:
// final RxString consentStatus = ''.obs;

// REPLACE fetchConsentStatus with a pure function that returns a value
  Future<String> fetchConsentStatus(String mobile) async {
    try {
      final statusList = await _reportService.getConsentStatus(mobile);
      if (statusList.isEmpty) return 'NO';
      return statusList.first.consentStatus.toUpperCase();
    } catch (e) {
      debugPrint('Error fetching consent status: $e');
      return 'NO';
    }
  }

// handleWhatsAppShare now just opens the sheet — consent fetch happens inside it
  void handleWhatsAppShare(PatientReportData report, String mobile) {
    shareToWhatsApp(report);
  }

  void shareToWhatsApp(PatientReportData report) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: Get.context!,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WhatsAppShareSheet(report: report),
    );

    if (result != null && result['send'] == true) {
      try {
        SnackBarService.to.showMessage(message: 'Sending report via WhatsApp…');
        final response = await _reportService.sendReportToWhatsApp(
         mobile: result['mobile'],
         barcode:  report.barcode,
        );
        SnackBarService.to.showMessage(
          message: response
              ? 'Report sent successfully'
              : 'Failed to send report. Please try again.',
        );
      } catch (e) {
        // SnackBarService.to.showMessage(message: 'Something went wrong. Try again.');
      }
    }
  }

  void sendConsent(String mobile) async {
    try {
      SnackBarService.to.showMessage(message: 'Sending consent request via WhatsApp…');
      final isSuccess = await _reportService.sendConsentToWhatsApp(mobile);
      SnackBarService.to.showMessage(
        message: isSuccess
            ? 'Consent request sent. Ask the patient to approve it.'
            : 'Could not send consent request. Try again.',
      );
    } catch (e) {
      // SnackBarService.to.showMessage(message: 'Something went wrong.');
    }
  }
/*  Future<void> fetchConsentStatus(String mobile) async {
    try {
      isLoading.value = true;
      labInfoError.value = '';
      facilityInfoError.value = '';

      final statusList = await _reportService.getConsentStatus(mobile);

      if (statusList.isEmpty) {
        consentStatus.value = 'NO';
        // SnackBarService.to.showMessage(message: 'No consent status found');
      } else {
        consentStatus.value = statusList.first.consentStatus;
        // consentStatus.value = "NO";
        debugPrint("Consent Status: ${consentStatus.value}");
      }
    } catch (e) {
      SnackBarService.to.showMessage(message: 'Failed to fetch consent status');
      debugPrint('Error fetching consent status: $e');
    } finally {
      isLoading.value = false;
    }
  }*/

  void filterReports(String query) {
    searchQuery.value = query.trim().toLowerCase();

    if (searchQuery.value.isEmpty) {
      filteredReports.assignAll(patientReports);
    } else {
      // Split search query into individual words
      final searchWords = searchQuery.value
          .split(' ')
          .where((word) => word.isNotEmpty)
          .toList();

      final matchingReports = patientReports.where((report) {
        final name = (report.patientName ?? '').toLowerCase();
        final mobile = (report.mobile ?? '').toLowerCase();
        final barcode = (report.barcode ?? '').toLowerCase();

        // Check if ALL search words are found in ANY of the fields
        final matches = searchWords.every((searchWord) {
          final found =
              name.contains(searchWord) ||
              mobile.contains(searchWord) ||
              barcode.contains(searchWord);

          return found;
        });

        return matches;
      }).toList();

      filteredReports.assignAll(matchingReports);
    }
  }

  // Report Actions
  void viewReport(PatientReportData report) async {
    if (report.reportLink.isNotEmpty == true) {
      try {
        Get.to(
          () => ReportPdfViewerPage(patientName: report.patientName),
          arguments: {
            'downloadUrl': report.reportLink,
            'barcode': report.barcode,
            'report': report,
          },
          transition: Transition.circularReveal,
          duration: const Duration(milliseconds: 250),
        );

        debugPrint('Opening report: ${report.reportLink}');
      } catch (e) {
        SnackBarService.to.showMessage(message: 'Failed to open report');
      }
    }
  }

  void shareReport(PatientReportData report) async {
    if (shareBtnPressed.value) return;

    if (report.reportLink.isNotEmpty == true) {
      try {
        shareBtnLoadingStates[report.barcode] = true;
        shareBtnPressed.value = true;
        await Future.delayed(const Duration(seconds: 5)); // testing loading

        await inAppReportViewController.shareReportDirectly(report);

        debugPrint('Sharing report: ${report.reportLink}');
      } catch (e) {
        SnackBarService.to.showMessage(message: 'Failed to share report');
      } finally {
        shareBtnLoadingStates[report.barcode] = false;
        shareBtnPressed.value = false;
      }
    }
  }


  Future<void> makeCall(String mobile) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: mobile);
    try {
      await launchUrl(phoneUri);
    } catch (e) {
      SnackBarService.to.showMessage(message: 'Could not launch phone dialer');
    }
  }

  // Send WhatsApp message with report data and link
  Future<void> sendWhatsAppMessage(
    String mobile,
    PatientReportData report,
  ) async {
    try {
      // Format mobile number (remove spaces, country code if needed)
      String formattedMobile = mobile.replaceAll(RegExp(r'\D'), '');
      if (!formattedMobile.startsWith('+')) {
        // Assuming a default country code (e.g., +91 for India); adjust as needed
        formattedMobile = '+91$formattedMobile';
      }

      // Construct report message
      final String message =
          'Patient Report\n'
          'Name: ${report.patientName}\n'
          'Barcode: ${report.barcode}\n'
          'View Report: ${report.reportLink}';

      // Encode message for URL
      final String encodedMessage = Uri.encodeComponent(message);
      final Uri whatsappUri = Uri.parse(
        'whatsapp://send?phone=$formattedMobile&text=$encodedMessage',
      );

      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri);
      } else {
        Get.snackbar('Error', 'WhatsApp not installed or cannot open');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to send WhatsApp message');
    } finally {}
  }

  RxBool isSearchExpanded = false.obs;

  // NEW: Method to toggle search expansion
  void toggleSearchExpansion() {
    isSearchExpanded.value = !isSearchExpanded.value;
  }

  // NEW: Method to clear all filters
  void clearFilters() {
    selectedLabName.value = null;
    selectedFacilityName.value = null;
    fromDate.value = null;
    toDate.value = null;
    // Clear any error messages
    labInfoError.value = '';
  }

  final RxList<TestStatusModel> testDetails = <TestStatusModel>[].obs;
  final RxBool isTestDetailLoading = false.obs;
  final RxString activeFilter = 'all'.obs;

  void onReportCardTap(PatientReportData report) {

   print('feetching report Report barcode: ${report.barcode}');
    fetchTestDetails(report.barcode);
    HapticFeedback.lightImpact();

    Get.to(
          () => ReportDetailPage(),
      arguments: {'report': report},
      transition: Transition.circularReveal,
      duration: const Duration(milliseconds: 300),
    );
  }

  Future<void> fetchTestDetails(String barcode) async {
    try {
      isTestDetailLoading.value = true;
      testDetails.clear();
      activeFilter.value = 'all';
      final tests = await _reportService.getPatientTestList(barcode);
      tests.sort((a, b) => _order(a).compareTo(_order(b)));

      testDetails.assignAll(tests);
    } catch (e) {
      SnackBarService.to.showMessage(message: 'Failed to load test details');
    } finally {
      isTestDetailLoading.value = false;
    }
  }

  int _order(TestStatusModel t) {
    if (t.isReady) return 0;
    if (t.isInProcess) return 1;
    return 2;
  }

// In PatientReportController
  void applyTestFilter(String filter) {
    HapticFeedback.selectionClick();
    activeFilter.value = filter;
  }

  List<TestStatusModel> get filteredTests {
    if (activeFilter.value == 'ready') {
      return testDetails.where((t) => t.isReady).toList();
    }
    if (activeFilter.value == 'inprocess') {
      return testDetails.where((t) => t.isInProcess).toList();
    }
    return testDetails; // 'all'
  }
}
