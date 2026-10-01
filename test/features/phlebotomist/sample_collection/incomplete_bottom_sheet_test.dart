import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/model/patient_queue_model.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/model/barcode_formatter.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/model/sample_collection_models.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/view/widgets/incomplete_bottom_sheet.dart';

void main() {
  final reason = IncompleteReasonOption(
    reasonId: 2,
    reason: 'Patient not fasting',
  );
  late SampleBarcodeEntry entry;
  setUp(() {
    entry = SampleBarcodeEntry(
      sampleTypeId: 2,
      sampleType: 'Blood',
      volumeRequiredMl: '',
      tests: [
        TestInfo(
          testId: 101,
          testName: 'Fasting test',
          testCode: '',
          tubeTypes: [],
        ),
      ],
    );
    entry.testIncompleteMap[101] = TestIncompleteInfo(
      reason: reason,
      remarks: 'Patient confirmed',
      appointmentDate: DateTime.now(),
      slotId: 8,
      slotLabel: '08:00 – 08:30',
    );
  });
  tearDown(() => entry.dispose());

  Future<void> open(
    WidgetTester tester,
    ValueChanged<Map<int, TestIncompleteInfo>> confirm, {
    List<AvailableSlot> slots = const [
      AvailableSlot(slotId: 8, timeSlot: '08:00 – 08:30'),
    ],
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => IncompleteTestsBottomSheet(
                  entry: entry,
                  reasonOptions: [
                    reason,
                    IncompleteReasonOption(
                      reasonId: 3,
                      reason: 'Patient requested another visit',
                    ),
                  ],
                  onFetchSlots: (_) async => slots,
                  onConfirm: confirm,
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'reopening and confirming retains reason, note, date and API slot',
    (tester) async {
      Map<int, TestIncompleteInfo>? result;
      await open(tester, (value) => result = value);
      expect(find.text('Rescheduled tests'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(tester.takeException(), isNull);
      expect(find.text('Patient not fasting'), findsOneWidget);
      await tester.tap(find.text('Save changes').last);
      await tester.pumpAndSettle();
      expect(result![101]!.reason.reasonId, 2);
      expect(result![101]!.remarks, 'Patient confirmed');
      expect(
        result![101]!.appointmentDate,
        entry.testIncompleteMap[101]!.appointmentDate,
      );
      expect(result![101]!.slotId, 8);
      expect(result![101]!.slotLabel, '08:00 – 08:30');
    },
  );

  testWidgets(
    'unavailable draft slots cannot remove the saved collection time',
    (tester) async {
      Map<int, TestIncompleteInfo>? result;
      await open(tester, (value) => result = value, slots: []);
      await tester.ensureVisible(find.byIcon(Icons.event_available_rounded));
      await tester.tap(find.byIcon(Icons.event_available_rounded));
      await tester.pumpAndSettle();
      final timingButton = find.widgetWithText(
        ElevatedButton,
        'Confirm collection time',
      );
      expect(tester.widget<ElevatedButton>(timingButton).onPressed, isNull);
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Clear all'), findsNothing);
      expect(find.byType(Checkbox), findsNothing);
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(result![101]!.slotId, 8);
      expect(
        result![101]!.appointmentDate,
        entry.testIncompleteMap[101]!.appointmentDate,
      );
    },
  );
  testWidgets(
    'review shows only rescheduled tests and cancelling retains the saved plan',
    (tester) async {
      entry.tests.add(
        TestInfo(
          testId: 102,
          testName: 'Other test',
          testCode: '',
          tubeTypes: [],
        ),
      );
      Map<int, TestIncompleteInfo>? result;
      await open(tester, (value) => result = value);
      expect(find.byType(TextField), findsNothing);
      expect(
        find.byTooltip('Edit collection plan for Fasting test'),
        findsNothing,
      );
      expect(
        find.byTooltip('Edit collection plan for Other test'),
        findsNothing,
      );
      expect(find.byType(Checkbox), findsNothing);
      expect(find.textContaining('Other test'), findsNothing);
      expect(find.text('Fasting test'), findsOneWidget);
      expect(find.text('Patient not fasting'), findsOneWidget);
      expect(find.byIcon(Icons.event_available_rounded), findsOneWidget);
      expect(find.byIcon(Icons.expand_less_rounded), findsNothing);
      await tester.tap(find.byTooltip('Close review'));
      await tester.pumpAndSettle();
      expect(result, isNull);
      expect(entry.testIncompleteMap.keys, [101]);
      expect(entry.testIncompleteMap[101]!.remarks, 'Patient confirmed');
    },
  );
  testWidgets('changing reason and slot retains a complete appointment', (
    tester,
  ) async {
    Map<int, TestIncompleteInfo>? result;
    await open(
      tester,
      (value) => result = value,
      slots: [
        const AvailableSlot(slotId: 9, inTime: '13:00:00', outTime: '13:30:00'),
      ],
    );
    // The existing reason is selectable without resetting its appointment.
    await tester.tap(find.text('Patient not fasting'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Patient requested another visit'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.event_available_rounded));
    await tester.pumpAndSettle();
    expect(find.text('1:00 PM'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('collection-slot-9')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm collection time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(result![101]!.hasSchedule, isTrue);
    expect(result![101]!.reason.reasonId, 3);
    expect(result![101]!.slotId, 9);
    expect(result![101]!.slotLabel, '1:00 PM');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'multiple rescheduled tests show independent reason and timing rows',
    (tester) async {
      entry.tests.add(
        TestInfo(
          testId: 102,
          testName: 'Second fasting test',
          testCode: '',
          tubeTypes: [],
        ),
      );
      entry.testIncompleteMap[102] = TestIncompleteInfo(
        reason: IncompleteReasonOption(
          reasonId: 3,
          reason: 'Patient requested another visit',
        ),
        appointmentDate: DateTime.now().add(const Duration(days: 1)),
        slotId: 9,
        slotLabel: '1:00 PM',
      );
      Map<int, TestIncompleteInfo>? result;
      await open(tester, (value) => result = value);
      expect(find.text('Fasting test'), findsOneWidget);
      expect(find.text('Second fasting test'), findsOneWidget);
      expect(find.text('Patient not fasting'), findsOneWidget);
      expect(find.text('Patient requested another visit'), findsOneWidget);
      expect(find.byIcon(Icons.event_available_rounded), findsNWidgets(2));
      expect(find.textContaining('8:00 AM'), findsOneWidget);
      expect(find.textContaining('1:00 PM'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(result!.keys, [101, 102]);
      expect(result![101]!.reason.reasonId, 2);
      expect(result![101]!.slotId, 8);
      expect(result![102]!.reason.reasonId, 3);
      expect(result![102]!.slotId, 9);
      expect(
        result![102]!.appointmentDate,
        entry.testIncompleteMap[102]!.appointmentDate,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
