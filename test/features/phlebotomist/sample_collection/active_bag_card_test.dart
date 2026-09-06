// active_bag_card_test.dart
//
// Widget tests for the ActiveBagCard shown on the sample collection screen:
//  - the "no open bag" prompt when the phlebotomist has no open session,
//  - the open-bag card with live capacity figures and bag-switch actions.

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/model/patient_queue_model.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_registration/bag_status_dashboard/controller/registrarion_bag_controller.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_registration/bag_status_dashboard/model/qr_bag_details.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_registration/bag_status_dashboard/model/qr_bag_session.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/controller/sample_collection_controller.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/view/widgets/active_bag_card.dart';
import 'package:lifenity_connect/network/api_client.dart';
import 'package:lifenity_connect/network/session_coordinator.dart';
import 'package:lifenity_connect/services/auth_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal JSON for an [AssignedPatient]. Uses a non-actionable status so
/// the controller's init stops before any order-details network call.
Map<String, dynamic> _patientJson() => {
  'SampleCollectionOrderID': 33,
  'OrderID': 'ORD-1',
  'PatientID': 'PAT-1004',
  'FirstName': 'Rakul',
  'PatientName': 'Rakul Patil',
  'Status': 'Assigned',
  'Priority': 'Normal',
  'VisitType': 'Clinic',
  'Tests': <Map<String, dynamic>>[],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BagRegistrationController bagController;
  late SampleCollectionController controller;

  setUp(() {
    Get.reset();
    // AuthManager reads SharedPreferences — keep it empty so no user/session
    // load (and therefore no network call) is triggered from onInit.
    SharedPreferences.setMockInitialValues({});
    Get.put<APIClient>(
      APIClient(dio: Dio(), sessionManager: SessionCoordinator(AuthManager())),
    );
    Get.put<AuthManager>(AuthManager());

    bagController = Get.put(BagRegistrationController());
    controller = Get.put(
      SampleCollectionController(
        assignedPatient: AssignedPatient.fromJson(_patientJson()),
      ),
    );
  });

  Widget wrap() => MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: ActiveBagCard(controller: controller),
      ),
    ),
  );

  testWidgets('shows a no-open-bag prompt when no session is open',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('No open bag'), findsOneWidget);
    expect(find.text('Open New Bag'), findsOneWidget);
    // Capacity UI only exists on the open-bag card.
    expect(find.text('Capacity used'), findsNothing);
    expect(find.text('Change Bag'), findsNothing);
  });

  testWidgets('offers to reopen a closed assigned bag when nothing is open',
      (tester) async {
    // Phlebo has an assigned bag that was closed — reopening it should be
    // offered instead of forcing the new-bag scan flow.
    bagController.allSessions.assignAll([
      QRBagSession(
        sessionID: 14,
        bagId: 42,
        bagcode: '01030100020',
        bagCloseStatus: 1,
      ),
    ]);

    await tester.pumpWidget(wrap());
    await tester.pump();

    // Reopen-first prompt, with the closed bag's code in the subtitle.
    expect(find.text('No open bag'), findsOneWidget);
    expect(find.textContaining('01030100020'), findsOneWidget);
    expect(find.text('Reopen Bag'), findsOneWidget);
    expect(find.text('New Bag'), findsOneWidget);
    // The scan flow is no longer the only option.
    expect(find.text('Open New Bag'), findsNothing);
  });

  testWidgets('several closed bags route through the bag picker',
      (tester) async {
    bagController.allSessions.assignAll([
      QRBagSession(
        sessionID: 14,
        bagId: 42,
        bagcode: 'BAG-42',
        bagCloseStatus: 1,
      ),
      QRBagSession(
        sessionID: 15,
        bagId: 37,
        bagcode: 'BAG-37',
        bagCloseStatus: 1,
      ),
    ]);

    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.text('Reopen a Bag'), findsOneWidget);
    expect(find.text('New Bag'), findsOneWidget);
    expect(find.text('Open New Bag'), findsNothing);
  });

  testWidgets('shows the open bag with capacity and bag actions',
      (tester) async {
    bagController.allSessions.assignAll([
      QRBagSession(
        sessionID: 12,
        bagId: 40,
        bagcode: 'BAG-40',
        bagCloseStatus: 0,
      ),
      QRBagSession(
        sessionID: 11,
        bagId: 39,
        bagcode: 'BAG-39',
        bagCloseStatus: 1,
      ),
    ]);
    bagController.bagDetailsMap[40] = QRBagDetails(
      qrCode: 'BAG-40',
      capacity: 10,
      patientCount: 6,
      spaceVacant: 4,
    );

    await tester.pumpWidget(wrap());
    // The live badge animates forever — pump frames, never pumpAndSettle.
    await tester.pump();
    await tester.pump();

    // Header: bag code + live badge.
    expect(find.text('BAG-40'), findsOneWidget);
    expect(find.text('OPEN'), findsOneWidget);

    // Capacity: 6 of 10 used → 60%.
    expect(find.text('60%'), findsOneWidget);
    expect(find.text('Used'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('Vacant'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Capacity'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);

    // Actions.
    expect(find.text('Change Bag'), findsOneWidget);
    expect(find.text('New Bag'), findsOneWidget);
  });

  testWidgets('a nearly-full bag surfaces the amber warning', (tester) async {
    bagController.allSessions.assignAll([
      QRBagSession(
        sessionID: 12,
        bagId: 40,
        bagcode: 'BAG-40',
        bagCloseStatus: 0,
      ),
    ]);
    bagController.bagDetailsMap[40] = QRBagDetails(
      qrCode: 'BAG-40',
      capacity: 10,
      patientCount: 9,
      spaceVacant: 1,
    );

    await tester.pumpWidget(wrap());
    await tester.pump();
    await tester.pump();

    expect(
      find.text('This bag is almost full. Consider switching to a new bag soon.'),
      findsOneWidget,
    );
  });
}