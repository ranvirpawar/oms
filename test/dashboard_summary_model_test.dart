import 'package:flutter_test/flutter_test.dart';
import 'package:lifenity_connect/features/dashboard/model/dashboard_summary_model.dart';

void main() {
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

  DashboardSummaryItem parse(Map<String, dynamic> row) => PhleboDashboardSummary.fromJson({
    'status': 'Success', 'message': 'GetPhleboDashboardSummary details', 'output': [row],
  }).output.single;

  test('parses phlebotomist counts from the dashboard response', () {
    final item = parse({'UserID': 29, 'AssignedPatientsCount': 28, 'ClinicCollectionRequestCount': 6, 'HomeRequestCount': 22, 'ServedRequests': 2});
    expect(item.userId, 29);
    expect([item.assignedPatientsCount, item.clinicCollectionRequestCount, item.homeRequestCount, item.servedRequests], [28, 6, 22, 2]);
  });
  test('runner fields are distinct and preserve nonzero values', () {
    final item = parse({'UserID': 45, 'ReadyForPickUp': 3, 'PickedUp': 4, 'SubmittoLab': 5, 'AcceptedinLab': 6});
    expect([item.readyForPickUp, item.pickedUp, item.submitToLab, item.acceptedInLab], [3, 4, 5, 6]);
    expect(item.assignedPatientsCount, 0);
  });
  test('lab response works without phlebotomist or runner fields', () {
    final item = parse({'UserID': 48, 'SubmittoLab': 0, 'AcceptedinLab': 0});
    expect([item.submitToLab, item.acceptedInLab, item.readyForPickUp], [0, 0, 0]);
  });
  test('empty output and numeric strings are supported', () {
    expect(PhleboDashboardSummary.fromJson({'status': 'Success', 'output': null}).output, isEmpty);
    expect(parse({'PickedUp': '7'}).pickedUp, 7);
    expect(parse({'PickedUp': null}).pickedUp, 0);
  });
}
