import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/features/cms_eho/view/consumption_dashboard.dart';
import 'package:lifenity_connect/features/dashboard/view/dashboard_screen.dart';
import 'package:lifenity_connect/features/lab_technician/passkey/view/passkey_view.dart';
import 'package:lifenity_connect/features/lab_technician/sample_accept/view/sample_accept_view.dart';
import 'package:lifenity_connect/features/phlebotomist/accept_bag/view/accept_bag_view.dart';
import 'package:lifenity_connect/features/phlebotomist/bag_status/view/bag_status_page.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/view/patient_queue_view.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_registration/bag_status_dashboard/view/patient_registration_dashboard.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_registration/view/registered_patient_list.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/view/order_confirmation_screen.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_pickup/view/sample%20pickup_entry.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_recollection/view/sample_recollection_list_view.dart';
import 'package:lifenity_connect/features/phlebotomist/user_attendance/view/user_attendance.dart';
import 'package:lifenity_connect/features/runner_boy/collect_empty_bag/view/collect_destination_bag.dart';
import 'package:lifenity_connect/features/runner_boy/collect_from_phlebotomist/view/collect_bag_from_phlebo.dart';
import 'package:lifenity_connect/features/team_lead/invoice_tracking/view/invoice_tracking_view.dart';
import 'package:lifenity_connect/features/runner_boy/collected_sample_bags/view/collected_bags_view.dart';
import 'package:lifenity_connect/features/runner_boy/handover_to_connector/view/handover_to_connector_view.dart';
import 'package:lifenity_connect/features/runner_boy/handover_to_phlebo/view/handover_phlebotomist_view.dart';
import 'package:lifenity_connect/features/team_lead/sample_remark/view/sample_remark_view.dart';
import 'package:lifenity_connect/features/cms_eho/view/performance_dashboard.dart';
import 'package:lifenity_connect/features/cms_eho/view/summary_dashboard.dart';
import 'package:lifenity_connect/features/team_lead/visit_details/view/visit_details_screen.dart';
import 'package:lifenity_connect/features/team_lead/zero_sample_calendar/view/zero_calendar_view.dart';
import 'package:lifenity_connect/routes/dependancy_injection/sample_collection_binding.dart';

import '../features/dashboard/dashboard_controller/dashboard_controller.dart';
import '../features/lab_technician/accept_handover_bag/view/accept_bag_in_lab_view.dart';
import '../features/lab_technician/accept_handover_bag/view/handover_bag_view.dart';
import '../features/phlebotomist/facility_count_dashboard/view/facility_count_dashboard.dart';
import '../features/phlebotomist/patient_queue/model/patient_queue_model.dart';
import '../features/phlebotomist/patient_registration/view/patient_detail_page.dart';
import '../features/phlebotomist/patient_registration/view/patient_registration_view.dart';
import '../features/phlebotomist/patient_report/view/patient_report_view.dart';
import '../features/phlebotomist/sample_collection/view/sample_collection_screen.dart';
import '../features/phlebotomist/sample_recollection/controller/sample_recollection_controller.dart';
import '../features/cms_eho/view/test_analysis_page.dart';
import '../features/team_lead/barcode_merging/view/merge_barcode_view.dart';
import '../features/team_lead/sample_live_tracking/view/live_tracking_view.dart';
import 'dependancy_injection/patient_queue_binding.dart';

class RouteManager {
  static void redirectToHomeDashboard() {
    if (!Get.isRegistered<DashboardController>()) {
      Get.delete<DashboardController>();
    }
    Get.offAll(() => DashboardScreen(), transition: Transition.fadeIn);
  }

  static void redirectToLogin() {}

  static void redirectToForgotPassword() {}

  static void redirectToSignUp() {}

  static void navigateToPatientRegistration(String bagId) {
    Get.to(
      () => PatientRegistrationPage(),
      arguments: {'bagId': bagId},
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 200),
    );
  }

  static void navigateToBagStatusDashboard({isBack = false}) {
    if (isBack) {
      Get.off(
        () => const PatientRegistrationDashboard(),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 200),
      );
    } else {
      Get.to(
        () => const PatientRegistrationDashboard(),
        transition: Transition.rightToLeft,
        duration: const Duration(milliseconds: 200),
      );
    }
  }

  static void navigateToPatientRegistrationDashboard({isQuick = false}) {
    Get.to(
      () => FacilityRegistrationPage(),
      transition: Transition.rightToLeft,
      duration: Duration(milliseconds: isQuick ? 0 : 200),
    );
  }

  static void navigateToPatientDetailPage(patient, controller) {
    Get.to(
      () => PatientDetailPage(patient: patient, controller: controller),
      transition: Transition.cupertino,
    );
  }

  static void navigateToSampleAccept() {
    Get.to(
      () => const SampleAcceptView(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 200),
    );
  }

  static void navigateToSamplePickupDashboard() {
    Get.to(
      () => SamplePickupEntryView(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 200),
    );
  }

  static void navigateToPatientReport() {
    Get.to(
      () => PatientReportView(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 200),
    );
  }

  static void navigateToSampleRecollection([bool isRefresh = false]) {
    if (isRefresh) {
      if (Get.isRegistered<SampleRecollectionController>()) {
        Get.delete<SampleRecollectionController>(force: true);
      }
    }

    Get.to(
      () => SampleRecollectionView(isRefresh: isRefresh),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 200),
    );
  }

  static void navigateToGeneratePassKey(String userId) {
    Get.to(
      () => PasskeyScreen(userId: userId),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 200),
    );
  }

  static void navigateToPatientRegistrationList({
    required dynamic facilityData,
    required DateTime fromDate,
    DateTime? toDate,
  }) {
    Get.to(
      () => const PatientRegistrationList(),
      arguments: {
        'facilityId': facilityData.facilityId,
        'facilityName': facilityData.facilityName,
        'fromDate': fromDate,
        'toDate': toDate ?? fromDate,
      },
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 200),
    );
  }

  static void navigateToAcceptBag() {
    Get.to(
      () => AcceptBagView(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 200),
    );
  }

  static void navigateToBagStatus() {
    Get.to(
      () => const BagStatusPage(),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 200),
    );
  }

  /*------------------ Team Lead --------------------- */

  static void navigateToSampleRemark() {
    Get.to(
      () => SampleRemarkView(),
      transition: Transition.circularReveal,
      duration: const Duration(milliseconds: 200),
    );
  }

  static void navigateToZeroSampleCalendar() {
    Get.to(
      () => ZeroSampleCalendarView(),
      transition: Transition.circularReveal,
      duration: const Duration(milliseconds: 200),
    );
  }

  static void navigateToVisitDetails() {
    Get.to(
      () => const ProviderScope(child: VisitDetailsScreen()),
      transition: Transition.circularReveal,
      duration: const Duration(milliseconds: 200),
    );
  }

  static void navigateTOTLDashboard() {
    Get.to(
      () => SummaryDashboard(),
      transition: Transition.circularReveal,
      duration: const Duration(milliseconds: 200),
    );
  }

  static void navigateToTestAnalysisDashboard() {
    Get.to(
      () => TestAnalysisDashboard(),
      transition: Transition.circularReveal,
      duration: const Duration(milliseconds: 200),
    );
  }

  static void navigateToPerformanceDashboard() {
    Get.to(
      () => PerformanceDashboard(),
      transition: Transition.circularReveal,
      duration: const Duration(milliseconds: 200),
    );
  }

  // route to consumption dashboard
  static void navigateToConsumptionDashboard() {
    Get.to(
      () => const ConsumptionDashboard(),
      transition: Transition.circularReveal,
      duration: const Duration(milliseconds: 200),
    );
  }

  static void navigateToInvoiceTracking() {
    Get.to(
      () => InvoiceTrackingView(),
      transition: Transition.circularReveal,
      duration: const Duration(milliseconds: 200),
    );
  }

  static void navigateToSampleLiveTracking() {
    Get.to(
      () => LiveTrackingView(),
      transition: Transition.circularReveal,
      duration: const Duration(milliseconds: 200),
    );
  }

  static void navigateToMergeBarcode() {
    Get.to(
      () => MergeBarcodeView(),
      transition: Transition.circularReveal,
      duration: const Duration(milliseconds: 200),
    );
  }

  /// runner boy
  ///  Collect Empty Bag
  /*------------------Runner Boy Routes --------------------*/
  static void navigateToCollectEmptyBag() {
    Get.to(
      () => const CollectDestinationBagView(),
      transition: Transition.circularReveal,
      duration: const Duration(milliseconds: 200),
    );
  }

  static void navigateToHandoverPhlebotomist() {
    Get.to(
      () => HandoverPhlebotomistView(),
      transition: Transition.circularReveal,
      duration: const Duration(milliseconds: 200),
    );
  }

  static void navigateToHandoverConnector() {
    Get.to(
      () => const HandoverConnectorView(),
      transition: Transition.circularReveal,
      duration: const Duration(milliseconds: 200),
    );
  }

  static void navigateToHandoverT0RunnerBoy() {
    Get.to(
      () => const HandoverConnectorView(isHandOverToRunnerBoy: true),
      transition: Transition.circularReveal,
      duration: const Duration(milliseconds: 200),
    );
  }

  static void navigateToCollectedBags() {
    Get.to(
      () => CollectedBagsView(),
      transition: Transition.circularReveal,
      duration: const Duration(milliseconds: 200),
    );
  }

  static void navigateToCollectBagsFromPhlebotomist() {
    Get.to(
      () => CollectBagFromPhlebotomistView(),
      transition: Transition.circularReveal,
      duration: const Duration(milliseconds: 200),
    );
  }

  /*------------------------ Lab Accession ----------------------*/
  static void navigateToAcceptBagInLaboratory() {
    Get.to(
      () => const AcceptBagInLabView(),
      transition: Transition.circularReveal,
      duration: const Duration(milliseconds: 200),
    );
  }

  static void navigateToHandOverBagToInventory() {
    Get.to(
      () => const HandoverBagView(),
      transition: Transition.circularReveal,
      duration: const Duration(milliseconds: 200),
    );
  }
  static void navigateToPatientQueue() {
    Get.to(
      () => const PatientQueueView(),
      binding: PatientQueueBinding(),
      transition: Transition.circularReveal,
      duration: const Duration(milliseconds: 200),
    );
  }

  static void navigateToSampleCollection(AssignedPatient patient) {
    Get.to(
          () => const OrderConfirmationScreen(),
      binding: SampleCollectionBinding(),
      arguments: {'assignedPatient': patient},
      transition: Transition.circularReveal,
      duration: const Duration(milliseconds: 200),
    );
  }
}
