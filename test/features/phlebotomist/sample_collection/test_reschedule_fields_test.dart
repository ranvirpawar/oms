import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/model/patient_queue_model.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/model/sample_collection_models.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/view/widgets/test_reschedule_fields.dart';

void main() {
  final reason = IncompleteReasonOption(
    reasonId: 2,
    reason: 'Patient not fasting',
  );
  test('start time supports persisted labels and missing API time safely', () {
    expect(formatCollectionStartTime('08:00 – 08:30'), '8:00 AM');
    expect(formatCollectionStartTime('13:00:00'), '1:00 PM');
    expect(formatCollectionStartTime('1:00 PM'), '1:00 PM');
    expect(formatCollectionStartTime(''), 'Selected time slot');
    expect(formatCollectionStartTime('invalid'), 'invalid');
  });
  Widget form({
    required Future<List<AvailableSlot>> Function(DateTime) fetch,
    required ValueChanged<TestIncompleteInfo> changed,
  }) => MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: TestRescheduleFields(
          testName: 'Fasting glucose',
          reasonOptions: [reason],
          onFetchSlots: fetch,
          onChanged: changed,
          initialInfo: TestIncompleteInfo(
            reason: reason,
            appointmentDate: DateTime.now(),
            slotId: 8,
            slotLabel: 'Old slot',
          ),
        ),
      ),
    ),
  );
  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.event_available_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets(
    'date and slot controls appear only in the sheet and confirm updates summary',
    (tester) async {
      final response = Completer<List<AvailableSlot>>();
      final changes = <TestIncompleteInfo>[];
      await tester.pumpWidget(
        form(fetch: (_) => response.future, changed: changes.add),
      );
      expect(find.text('Select date'), findsNothing);
      expect(find.byType(DropdownButtonFormField<int>), findsNothing);
      await open(tester);
      expect(find.text('Plan collection'), findsOneWidget);
      expect(find.text('Fasting glucose'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      response.complete([
        const AvailableSlot(slotId: 9, timeSlot: '09:00 – 09:30'),
      ]);
      await tester.pumpAndSettle();
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      expect(changes, isEmpty);
      await tester.tap(find.byKey(const ValueKey('collection-slot-9')));
      await tester.pumpAndSettle();
      expect(changes, isEmpty);
      await tester.tap(find.text('Confirm collection time'));
      await tester.pumpAndSettle();
      expect(changes.last.reason.reasonId, 2);
      expect(changes.last.slotId, 9);
      expect(changes.last.slotLabel, '9:00 AM');
      expect(find.text('Plan collection'), findsNothing);
      expect(find.textContaining('9:00 AM'), findsOneWidget);
    },
  );

  testWidgets(
    'slot errors allow retry without modifying the saved appointment',
    (tester) async {
      var calls = 0;
      final changes = <TestIncompleteInfo>[];
      await tester.pumpWidget(
        form(
          fetch: (_) async {
            calls++;
            if (calls == 1) throw Exception('Offline');
            return [];
          },
          changed: changes.add,
        ),
      );
      await open(tester);
      await tester.pumpAndSettle();
      expect(
        find.text('We could not load the time slots. Please try again.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(
        find.text(
          'No slots available for this date. Please choose another date.',
        ),
        findsOneWidget,
      );
      expect(changes, isEmpty);
    },
  );

  testWidgets('date change clears draft slot and ignores older API response', (
    tester,
  ) async {
    final responses = [
      Completer<List<AvailableSlot>>(),
      Completer<List<AvailableSlot>>(),
    ];
    final changes = <TestIncompleteInfo>[];
    final dates = <DateTime>[];
    await tester.pumpWidget(
      form(
        fetch: (date) {
          dates.add(date);
          return responses[dates.length - 1].future;
        },
        changed: changes.add,
      ),
    );
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('collection-date-1')));
    await tester.pump();
    expect(dates.length, 2);
    expect(dates[1].difference(dates[0]).inDays, 1);
    responses[1].complete([
      const AvailableSlot(slotId: 9, timeSlot: 'New slot'),
    ]);
    await tester.pumpAndSettle();
    responses[0].complete([
      const AvailableSlot(slotId: 8, timeSlot: 'Stale slot'),
    ]);
    await tester.pumpAndSettle();
    expect(find.text('New slot'), findsOneWidget);
    expect(find.text('Stale slot'), findsNothing);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('collection-slot-9')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm collection time'));
    await tester.pumpAndSettle();
    expect(changes.single.appointmentDate, dates[1]);
    expect(changes.single.slotId, 9);
  });

  testWidgets('closing the sheet discards draft date and slot', (tester) async {
    final changes = <TestIncompleteInfo>[];
    await tester.pumpWidget(
      form(
        fetch: (_) async => [
          const AvailableSlot(slotId: 9, timeSlot: 'New slot'),
        ],
        changed: changes.add,
      ),
    );
    await open(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('collection-slot-9')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
    expect(find.textContaining('Old slot'), findsOneWidget);
    expect(find.text('Plan collection'), findsNothing);
  });
}
