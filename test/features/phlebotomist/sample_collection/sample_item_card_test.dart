import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/model/patient_queue_model.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/controller/sample_collection_controller.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/model/barcode_formatter.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/model/sample_collection_models.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/view/widgets/barcode_input_field.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/view/widgets/sample_item_card.dart';
import 'package:lifenity_connect/network/api_client.dart';
import 'package:lifenity_connect/network/session_coordinator.dart';
import 'package:lifenity_connect/services/auth_manager.dart';

class _Controller extends SampleCollectionController {
  _Controller()
    : super(
        orderId: 'ORD-TEST',
        assignedPatient: AssignedPatient.fromJson({
          'OrderID': 'ORD-TEST',
          'SampleCollectionOrderID': 75,
          'Tests': <Map<String, dynamic>>[],
        }),
      );
  SampleBarcodeEntry? reviewed;
  @override
  void openIncompleteTestsSheet(SampleBarcodeEntry entry) => reviewed = entry;
  @override
  void onBarcodeChanged(
    SampleBarcodeEntry entry,
    String value, {
    bool immediate = false,
  }) {
    entry.barcodeStatus.value = BarcodeCheckStatus.available;
    entry.status.value = SampleCollectionStatus.collected;
  }
}

void main() {
  final reason = IncompleteReasonOption(
    reasonId: 2,
    reason: 'Patient not fasting',
  );
  final schedule = TestIncompleteInfo(
    reason: reason,
    appointmentDate: DateTime(2026, 10, 3),
    slotId: 8,
    slotLabel: '08:00 – 08:30',
  );
  late SampleBarcodeEntry entry;
  late _Controller controller;
  setUp(() {
    Get.reset();
    Get.put<APIClient>(
      APIClient(dio: Dio(), sessionManager: SessionCoordinator(AuthManager())),
    );
    controller = _Controller();
    entry = SampleBarcodeEntry(
      sampleTypeId: 2,
      sampleType: 'Blood',
      volumeRequiredMl: '',
      tests: [
        for (final id in [101, 102])
          TestInfo(
            testId: id,
            testCode: 'T$id',
            testName: id == 101 ? 'Fasting test' : 'Other test',
            tubeTypes: [TubeTypeInfo(tubeTypeId: 5, tubeType: 'EDTA')],
          ),
      ],
    );
    entry.testIncompleteMap[101] = schedule;
  });
  tearDown(() {
    entry.dispose();
    controller.onClose();
    Get.reset();
  });

  Future<void> showCard(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SampleItemCard(entry: entry, controller: controller),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('unavailability checks actual test IDs rather than map size', () {
    entry.testIncompleteMap[999] = schedule;
    expect(entry.isFullyUnusable, false);
    expect(entry.hasPartialIncomplete, true);
    entry.testIncompleteMap.remove(999);
    entry.testIncompleteMap[102] = schedule;
    expect(entry.isFullyUnusable, true);
  });

  testWidgets(
    'one rescheduled test keeps barcode available despite stale sample status',
    (tester) async {
      entry.status.value = SampleCollectionStatus.incomplete;
      await showCard(tester);
      expect(find.byType(TubeBarcodeGroup), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.event_repeat_rounded), findsOneWidget);
      expect(find.text('Review rescheduled tests'), findsNothing);
      expect(find.byTooltip('Review rescheduled tests'), findsOneWidget);
      expect(find.text('No tests to collect in this visit'), findsNothing);
      await tester.enterText(find.byType(TextField), 'JAA55584888');
      await tester.pumpAndSettle();
      expect(entry.barcodeController.text, 'JAA55584888');
      expect(entry.isCollected, true);
      expect(entry.testIncompleteMap.keys, [101]);
      await tester.tap(find.byTooltip('Review rescheduled tests'));
      expect(controller.reviewed, same(entry));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'barcode hides only when every test is unavailable and returns when one is restored',
    (tester) async {
      entry.testIncompleteMap[102] = schedule;
      await showCard(tester);
      expect(find.byType(TubeBarcodeGroup), findsNothing);
      expect(find.byIcon(Icons.event_repeat_rounded), findsNWidgets(2));
      entry.testIncompleteMap.remove(102);
      await tester.pumpAndSettle();
      expect(find.byType(TubeBarcodeGroup), findsOneWidget);
      expect(find.byIcon(Icons.event_repeat_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
