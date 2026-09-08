import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/controller/patient_queue_controller.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/model/patient_queue_model.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/service/patient_queue_service.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/model/sample_collection_models.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/service/sample_collection_service.dart';
import 'package:lifenity_connect/network/api_client.dart';
import 'package:lifenity_connect/network/session_coordinator.dart';
import 'package:lifenity_connect/services/auth_manager.dart';

/// Throws the configured [PatientQueueException] for every fetch, so the
/// controller's exception-handling paths can be tested without a network.
class _ThrowingService extends PatientQueueService {
  _ThrowingService(this.error);

  final PatientQueueException error;

  @override
  Future<List<AssignedPatient>> fetchAssignedPatients({
    required String userId,
  }) async {
    throw error;
  }
}

/// Returns a canned patient list so the controller's fetch path runs
/// without any real network call.
class _FakePatientQueueService extends PatientQueueService {
  _FakePatientQueueService(this.patients);

  final List<AssignedPatient> patients;

  @override
  Future<List<AssignedPatient>> fetchAssignedPatients({
    required String userId,
  }) async {
    return patients;
  }
}

/// Records the orderIds handed to [SampleCollectionService.resubmitToDisha]
/// (and can simulate a failure), so tests can assert the queue's
/// "Sync to LIS" button is wired to the right API call.
class _RecordingSampleCollectionService extends SampleCollectionService {
  _RecordingSampleCollectionService({this.shouldFail = false});

  final bool shouldFail;
  final List<String> resubmittedOrderIds = [];

  @override
  Future<bool> resubmitToDisha({required String orderId,required String userId }) async {
    if (shouldFail) {
      throw SampleCollectionException('Disha is not reachable.');
    }
    resubmittedOrderIds.add(orderId);
    return true;
  }
}

/// Minimal JSON for an [AssignedPatient], enough to exercise controller
/// logic without a real backend payload.
Map<String, dynamic> _jsonFor({
  required String orderId,
  required String status,
  String priority = 'Normal',
  String visitType = 'Clinic',
}) =>
    {
      'SampleCollectionOrderID': 33,
      'OrderID': orderId,
      'PatientID': 'PAT-1004',
      'FirstName': 'Rakul',
      'PatientName': 'Rakul Patil',
      'Status': status,
      'Priority': priority,
      'VisitType': visitType,
      'Tests': <Map<String, dynamic>>[],
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.reset();
    // PatientQueueService (and _ThrowingService's superclass) resolves
    // APIClient through GetX; AuthManager is used by the controller's
    // getUserdata() before the first fetch.
    Get.put<APIClient>(
      APIClient(dio: Dio(), sessionManager: SessionCoordinator(AuthManager())),
    );
    Get.put<AuthManager>(AuthManager());
  });

  test('fetchPatients maps a "No record found" failure to the empty state',
      () async {
    final service = _ThrowingService(PatientQueueException('No record found'));

    final controller = Get.put<PatientQueueController>(
      PatientQueueController(service: service),
    );

    await pumpEventQueue();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await pumpEventQueue();

    expect(controller.loadState.value, QueueLoadState.empty);
    expect(controller.filteredPatients, isEmpty);
  });

  test('fetchPatients surfaces a genuine failure in the error state', () async {
    final service = _ThrowingService(PatientQueueException('Server exploded'));

    final controller = Get.put<PatientQueueController>(
      PatientQueueController(service: service),
    );

    await pumpEventQueue();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await pumpEventQueue();

    expect(controller.loadState.value, QueueLoadState.error);
    expect(controller.errorMessage.value, 'Server exploded');
  });

  test('LIS-sync-failed "collect" orders are pinned to the top of the queue',
      () async {
    final urgentAccepted = AssignedPatient.fromJson(_jsonFor(
      orderId: 'ORD-URGENT',
      status: 'Accepted',
      priority: 'Urgent',
    ));
    final needsSync = AssignedPatient.fromJson(_jsonFor(
      orderId: 'ORD-SYNC',
      status: 'Collect',
    ));

    final controller = Get.put<PatientQueueController>(
      PatientQueueController(
        service: _FakePatientQueueService([urgentAccepted, needsSync]),
        sampleCollectionService: _RecordingSampleCollectionService(),
      ),
    );

    await pumpEventQueue();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await pumpEventQueue();

    expect(controller.filteredPatients, hasLength(2));
    expect(controller.filteredPatients.first.orderId, 'ORD-SYNC');
    expect(controller.filteredPatients.first.status, PatientStatus.collect);
    expect(controller.filteredPatients.first.status.isLisSyncFailed, isTrue);
    // And the urgent accepted order is second.
    expect(controller.filteredPatients[1].orderId, 'ORD-URGENT');
  });
  test('collection mode (bag registration) lists only Arrived orders',
      () async {
    final arrived = AssignedPatient.fromJson(_jsonFor(
      orderId: 'ORD-ARRIVED',
      status: 'Arrived',
    ));
    final assigned = AssignedPatient.fromJson(_jsonFor(
      orderId: 'ORD-ASSIGNED',
      status: 'Assigned',
    ));
    final accepted = AssignedPatient.fromJson(_jsonFor(
      orderId: 'ORD-ACCEPTED',
      status: 'Accepted',
    ));

    final controller = Get.put<PatientQueueController>(
      PatientQueueController(
        service: _FakePatientQueueService([arrived, assigned, accepted]),
        isCollectionMode: true,
      ),
    );

    await pumpEventQueue();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await pumpEventQueue();

    expect(controller.filteredPatients, hasLength(1));
    expect(controller.filteredPatients.first.orderId, 'ORD-ARRIVED');
    expect(controller.filteredPatients.first.status, PatientStatus.arrived);
    // Summary counts stay consistent with the narrowed list.
    expect(controller.totalCount, 1);
  });

  test('normal queue entry (no collection mode) keeps every status visible',
      () async {
    final arrived = AssignedPatient.fromJson(_jsonFor(
      orderId: 'ORD-ARRIVED',
      status: 'Arrived',
    ));
    final assigned = AssignedPatient.fromJson(_jsonFor(
      orderId: 'ORD-ASSIGNED',
      status: 'Assigned',
    ));

    final controller = Get.put<PatientQueueController>(
      PatientQueueController(
        service: _FakePatientQueueService([arrived, assigned]),
      ),
    );

    await pumpEventQueue();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await pumpEventQueue();

    expect(controller.filteredPatients, hasLength(2));
    expect(controller.totalCount, 2);
  });

  testWidgets(
      'syncToLis resubmits the order to Disha with the right order id '
      'then refreshes the queue', (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));

    final recordingService = _RecordingSampleCollectionService();
    final needsSync = AssignedPatient.fromJson(_jsonFor(
      orderId: 'ORD-SYNC',
      status: 'Collect',
    ));

    final controller = Get.put<PatientQueueController>(
      PatientQueueController(
        service: _FakePatientQueueService([needsSync]),
        sampleCollectionService: recordingService,
      ),
    );
    await tester.pumpAndSettle();

    await controller.syncToLis(needsSync);
    await tester.pumpAndSettle();

    expect(recordingService.resubmittedOrderIds, ['ORD-SYNC']);
    expect(controller.processingIds, isEmpty);

    // Let GetX auto-dismiss the success snackbar so no timer is left pending.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('syncToLis unlocks the card when the LIS resync fails',
      (tester) async {
    await tester.pumpWidget(const GetMaterialApp(home: SizedBox()));

    final recordingService = _RecordingSampleCollectionService(
      shouldFail: true,
    );
    final needsSync = AssignedPatient.fromJson(_jsonFor(
      orderId: 'ORD-SYNC',
      status: 'Collect',
    ));

    final controller = Get.put<PatientQueueController>(
      PatientQueueController(
        service: _FakePatientQueueService([needsSync]),
        sampleCollectionService: recordingService,
      ),
    );
    await tester.pumpAndSettle();

    await controller.syncToLis(needsSync);
    await tester.pumpAndSettle();

    expect(recordingService.resubmittedOrderIds, isEmpty);
    // The syncing spinner/lock is released even on failure.
    expect(controller.processingIds, isEmpty);

    // Let GetX auto-dismiss the error snackbar so no timer is left pending.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });
}