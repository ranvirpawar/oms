import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/model/patient_queue_model.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/view/widgets/patient_card.dart';

/// Minimal JSON for a "collect" (LIS sync failed) order — enough to render
/// the queue card in isolation.
Map<String, dynamic> _collectOrderJson() => {
  'SampleCollectionOrderID': 33,
  'OrderID': 'ORD-SYNC',
  'PatientID': 'PAT-1004',
  'FirstName': 'Rakul',
  'PatientName': 'Rakul Patil',
  'Status': 'Collect',
  'Priority': 'Normal',
  'VisitType': 'Clinic',
  'Tests': <Map<String, dynamic>>[],
};

Widget _wrap(AssignedPatient patient, {VoidCallback? onSyncToLis}) {
  return MaterialApp(
    home: Scaffold(
      body: PatientCard(
        patient: patient,
        isProcessing: false,
        onTapDetails: () {},
        onSyncToLis: onSyncToLis,
      ),
    ),
  );
}

void main() {
  testWidgets(
      'a "collect" order shows the LIS-sync-pending UI and no regular actions',
      (tester) async {
    final patient = AssignedPatient.fromJson(_collectOrderJson());

    await tester.pumpWidget(_wrap(patient));

    // Name + basic details remain visible on the card.
    expect(find.text('Rakul Patil'), findsOneWidget);
    expect(find.textContaining('ORD-SYNC'), findsOneWidget);

    // "Action Needed" badge + LIS callout + Sync button.
    expect(find.text('Action Needed'), findsOneWidget);
    expect(find.text('LIS sync pending'), findsOneWidget);
    expect(find.text('Sync to LIS'), findsOneWidget);

    // The regular assignment actions are hidden for this state.
    expect(find.text('Accept'), findsNothing);
    expect(find.text('Reject'), findsNothing);
    expect(find.text('Reschedule'), findsNothing);
  });

  testWidgets('the Sync to LIS button fires onSyncToLis for a collect order',
      (tester) async {
    final patient = AssignedPatient.fromJson(_collectOrderJson());
    var synced = false;

    await tester.pumpWidget(
      _wrap(patient, onSyncToLis: () => synced = true),
    );

    await tester.tap(find.text('Sync to LIS'));
    await tester.pump();

    expect(synced, isTrue);
  });
}