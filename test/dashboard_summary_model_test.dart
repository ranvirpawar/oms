import 'package:flutter_test/flutter_test.dart';
import 'package:lifenity_connect/features/dashboard/model/dashboard_summary_model.dart';

void main() {
  test('dynamic columns use API order and skip metadata and tube rows', () {
    final response = PhleboDashboardSummary.fromJson({
      'status': 'Success',
      'output': [
        {'RowType': 'Tubecount', 'UserID': 17, 'Assigned Patients': 9},
        {
          'RowType': 'PateintCount',
          'UserID': 17,
          'Assigned Patients': 4,
          'Clinic Collections': 1,
          'Home Collections': '3',
          'Samples Collected': 0,
          'New Backend Metric': null,
          'Description': 'not a count',
        },
      ],
    });
    expect(response.metrics.map((m) => m.label), [
      'Assigned Patients',
      'Clinic Collections',
      'Home Collections',
      'Samples Collected',
      'New Backend Metric',
    ]);
    expect(response.metrics.map((m) => m.value), [4, 1, 3, 0, 0]);
    expect(
      PhleboDashboardSummary.fromJson(
        response.toJson(),
      ).metrics.map((m) => m.key),
      response.metrics.map((m) => m.key),
    );
  });

  test(
    'runner and lab labels are taken directly from their response columns',
    () {
      for (final row in [
        {
          'UserID': 45,
          'RowType': 'OrderCount',
          'Ready For Pick-Up': 2,
          'Picked Up': 3,
          'Submit To Lab': 4,
          'Accepted In Lab': 5,
        },
        {
          'UserID': 48,
          'RowType': 'PatientCount',
          'Submitted To Lab': 6,
          'Accepted In Lab': 7,
        },
      ]) {
        final response = PhleboDashboardSummary.fromJson({
          'output': [row],
        });
        expect(response.metrics.map((m) => m.key), row.keys.skip(2));
        expect(response.metrics.last.label, 'Accepted In Lab');
        expect(response.metrics.last.value, row['Accepted In Lab']);
      }
    },
  );

  test(
    'labels format separators, camel case and casing without a label map',
    () {
      for (final key in [
        'acceptedInLab',
        'ACCEPTED_IN_LAB',
        '  accepted  in lab  ',
        'Accepted-in-Lab',
      ]) {
        expect(
          DashboardSummaryMetric(key: key, value: 0).label,
          'Accepted In Lab',
        );
      }
    },
  );

  test('missing and tube-only summaries do not invent dashboard metrics', () {
    expect(PhleboDashboardSummary.fromJson({'output': []}).metrics, isEmpty);
    expect(
      PhleboDashboardSummary.fromJson({
        'output': [
          {'RowType': 'TubeCount', 'Accepted In Lab': 8},
        ],
      }).metrics,
      isEmpty,
    );
  });

  test('no record found is an empty result, not an API error', () {
    final response = PhleboDashboardSummary.fromJson({
      'status': 'Fail',
      'message': 'No record found',
      'output': [],
    });
    expect(response.isEmptyResult, isTrue);
    expect(response.output, isEmpty);
  });

  test('other failures must not be treated as empty results', () {
    final response = PhleboDashboardSummary.fromJson({
      'status': 'Fail',
      'message': 'Unable to retrieve dashboard',
      'output': [],
    });
    expect(response.isEmptyResult, isFalse);
  });

  DashboardSummaryItem parse(Map<String, dynamic> row) =>
      PhleboDashboardSummary.fromJson({
        'status': 'Success',
        'message': 'GetPhleboDashboardSummary details',
        'output': [row],
      }).output.single;

  test('parses phlebotomist counts from the dashboard response', () {
    final item = parse({
      'UserID': 29,
      'AssignedPatientsCount': 28,
      'ClinicCollectionRequestCount': 6,
      'HomeRequestCount': 22,
      'ServedRequests': 2,
    });
    expect(item.userId, 29);
    expect(
      [
        item.assignedPatientsCount,
        item.clinicCollectionRequestCount,
        item.homeRequestCount,
        item.servedRequests,
      ],
      [28, 6, 22, 2],
    );
  });
  test('runner fields are distinct and preserve nonzero values', () {
    final item = parse({
      'UserID': 45,
      'ReadyForPickUp': 3,
      'PickedUp': 4,
      'SubmittoLab': 5,
      'AcceptedinLab': 6,
    });
    expect(
      [
        item.readyForPickUp,
        item.pickedUp,
        item.submitToLab,
        item.acceptedInLab,
      ],
      [3, 4, 5, 6],
    );
    expect(item.assignedPatientsCount, 0);
  });
  test('lab response works without phlebotomist or runner fields', () {
    final item = parse({'UserID': 48, 'SubmittoLab': 0, 'AcceptedinLab': 0});
    expect(
      [item.submitToLab, item.acceptedInLab, item.readyForPickUp],
      [0, 0, 0],
    );
  });
  test('empty output and numeric strings are supported', () {
    expect(
      PhleboDashboardSummary.fromJson({
        'status': 'Success',
        'output': null,
      }).output,
      isEmpty,
    );
    expect(parse({'PickedUp': '7'}).pickedUp, 7);
    expect(parse({'PickedUp': null}).pickedUp, 0);
  });
}
