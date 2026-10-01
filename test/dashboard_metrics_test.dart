import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifenity_connect/features/dashboard/model/dashboard_metrics.dart';
import 'package:lifenity_connect/features/dashboard/model/dashboard_summary_model.dart';
import 'package:lifenity_connect/features/dashboard/view/widget/dashboard_metrics_strip.dart';
import 'package:lifenity_connect/utils/widgets/metrics_data.dart';

void main() {
  test(
    'colors are generated and retained when counts and column order change',
    () {
      final presenter = DashboardMetrics(random: Random(42));
      final first = presenter.build(const [
        DashboardSummaryMetric(key: 'Accepted In Lab', value: 3),
        DashboardSummaryMetric(key: 'Future Metric', value: 0),
      ]);
      final refreshed = presenter.build(const [
        DashboardSummaryMetric(key: 'Future Metric', value: 8),
        DashboardSummaryMetric(key: 'Accepted In Lab', value: 14),
      ]);
      expect(first.first.value, '03');
      expect(refreshed.last.value, '14');
      expect(first.first.dot, refreshed.last.dot);
      expect(first.last.dot, refreshed.first.dot);
      expect(first.first.dot, isNot(first.last.dot));
    },
  );

  testWidgets(
    'API columns render with generated labels and scroll when extended',
    (tester) async {
      final response = PhleboDashboardSummary.fromJson({
        'output': [
          {
            'UserID': 48,
            'RowType': 'PatientCount',
            'Submitted To Lab': 4,
            'Accepted In Lab': 7,
            'Extra One': 1,
            'Extra Two': 2,
            'Extra Three': 3,
            'Extra Four': 4,
          },
          {'UserID': 48, 'RowType': 'TubeCount', 'Submitted To Lab': 99},
        ],
      });
      final items = DashboardMetrics(
        random: Random(42),
      ).build(response.metrics);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: DashboardMetricsStrip(items: items),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Submitted To Lab'), findsOneWidget);
      expect(find.text('Accepted In Lab'), findsOneWidget);
      expect(find.text('07'), findsOneWidget);
      expect(find.text('99'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(-300, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('Extra Four').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (var count = 1; count <= 5; count++) {
    testWidgets(
      '$count columns fit without scrolling and reserve two label lines',
      (tester) async {
        final items = List.generate(
          count,
          (index) => MetricData(
            value: index == 0 ? '123456' : '01',
            label: index == 0 ? 'Total' : 'A very long backend column label',
            dot: Colors.blue,
          ),
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 280,
                  child: DashboardMetricsStrip(items: items),
                ),
              ),
            ),
          ),
        );
        expect(find.byType(SingleChildScrollView), findsNothing);
        expect(find.byType(FittedBox), findsNWidgets(count + 1));
        final heights = <double>[];
        for (final cell in find.byType(MetricCell).evaluate()) {
          final label = find
              .descendant(
                of: find.byWidget(cell.widget),
                matching: find.byType(Text),
              )
              .last;
          final text = tester.widget<Text>(label);
          expect(text.maxLines, 2);
          expect(text.overflow, TextOverflow.ellipsis);
          final box = find
              .ancestor(of: label, matching: find.byType(SizedBox))
              .first;
          heights.add(tester.getSize(box).height);
        }
        expect(heights.toSet().length, 1);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('empty metrics render safely', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DashboardMetricsStrip(items: [])),
    );
    expect(tester.takeException(), isNull);
  });
}
