import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifenity_connect/componenents/otp_boxes_input.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('renders the requested number of boxes', (tester) async {
    await tester.pumpWidget(_wrap(const OtpBoxesInput(length: 4)));

    expect(find.byType(OtpBoxesInput), findsOneWidget);
    // One visible AnimatedContainer box per digit.
    expect(
      find.descendant(
        of: find.byType(OtpBoxesInput),
        matching: find.byType(AnimatedContainer),
      ),
      findsNWidgets(4),
    );
  });

  testWidgets('shows initialCode prefilled without firing callbacks',
      (tester) async {
    String? changed;
    String? completed;

    await tester.pumpWidget(_wrap(OtpBoxesInput(
      length: 4,
      initialCode: '12',
      onChanged: (v) => changed = v,
      onCompleted: (v) => completed = v,
    )));
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(changed, isNull);
    expect(completed, isNull);
  });

  testWidgets('typing digits updates boxes and fires onChanged/onCompleted',
      (tester) async {
    final values = <String>[];
    String? completed;

    await tester.pumpWidget(_wrap(OtpBoxesInput(
      length: 4,
      onChanged: values.add,
      onCompleted: (v) => completed = v,
    )));
    // Let the post-frame autofocus run.
    await tester.pump();

    await tester.enterText(find.byType(TextField), '12');
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(values.last, '12');
    expect(completed, isNull);

    await tester.enterText(find.byType(TextField), '1234');
    await tester.pump();

    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(values.last, '1234');
    expect(completed, '1234');
  });

  testWidgets('rejects non-digit input via the internal formatter',
      (tester) async {
    String last = '';

    await tester.pumpWidget(_wrap(OtpBoxesInput(
      length: 4,
      onChanged: (v) => last = v,
    )));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'ab1c2');
    await tester.pump();

    expect(last, '12');
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('setCode fills, truncates, clears, and fires onCompleted',
      (tester) async {
    final key = GlobalKey<OtpBoxesInputState>();
    String? completed;

    await tester.pumpWidget(_wrap(OtpBoxesInput(
      key: key,
      length: 4,
      onCompleted: (v) => completed = v,
    )));
    await tester.pump();

    // Longer than length -> truncated to the first 4 digits.
    key.currentState!.setCode('98765');
    await tester.pump();
    expect(key.currentState!.code, '9876');
    expect(completed, '9876');

    key.currentState!.clear();
    await tester.pump();
    expect(key.currentState!.code, '');
    expect(find.text('9'), findsNothing);
  });

  testWidgets('advertises oneTimeCode SMS autofill by default',
      (tester) async {
    await tester.pumpWidget(_wrap(const OtpBoxesInput()));

    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields, hasLength(1));
    expect(fields.first.autofillHints, [AutofillHints.oneTimeCode]);
  });

  testWidgets('does not advertise SMS autofill when enableAutofill is false',
      (tester) async {
    await tester.pumpWidget(_wrap(const OtpBoxesInput(enableAutofill: false)));

    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields, hasLength(1));
    expect(fields.first.autofillHints, isNull);
  });

  testWidgets('tapping a box does not throw', (tester) async {
    await tester.pumpWidget(_wrap(const OtpBoxesInput(length: 4)));
    await tester.pump();

    await tester.tap(find.byType(AnimatedContainer).first);
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'survives unmount/remount without "controller used after being disposed"',
      (tester) async {
    // Regression: the old login OTP boxes used an externally-owned
    // TextEditingController that could be disposed before this widget's own
    // teardown ran, crashing with "used after being disposed". This widget
    // owns its controller internally, so arbitrary mount/unmount sequences
    // must be safe.
    await tester.pumpWidget(_wrap(const OtpBoxesInput(length: 4)));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '1234');
    await tester.pump();

    // Replace the whole tree while the OTP input is populated.
    await tester.pumpWidget(_wrap(const SizedBox()));
    await tester.pump();

    // Remount fresh — no stale controller state should survive.
    await tester.pumpWidget(_wrap(const OtpBoxesInput(length: 4)));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}