import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/model/patient_queue_model.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/service/patient_queue_service.dart';
import 'package:lifenity_connect/network/api_client.dart';
import 'package:lifenity_connect/network/session_coordinator.dart';
import 'package:lifenity_connect/services/auth_manager.dart';

/// Dio adapter that returns a canned JSON body for every request, so the
/// real [APIClient] transport path is exercised end-to-end in the test.
class _StubHttpAdapter implements HttpClientAdapter {
  _StubHttpAdapter(this.body);

  final dynamic body;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final encoded = body is String ? body : jsonEncode(body);
    return ResponseBody.fromString(encoded, 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }
}

PatientQueueService _buildService(
  TestWidgetsFlutterBinding binding,
  dynamic responseBody,
) {
  final dio = Dio();
  dio.httpClientAdapter = _StubHttpAdapter(responseBody);
  Get.put<APIClient>(
    APIClient(
      dio: dio,
      sessionManager: SessionCoordinator(AuthManager()),
    ),
  );
  return PatientQueueService();
}

// Mirrors the sample order payload documented in patient_queue_service.dart.
Map<String, dynamic> _sampleOutput() => {
  'SampleCollectionOrderID': 33,
  'OMSOrderID': 'CL26090100000033',
  'OrderID': 'TEST-ORD-20260901-005',
  'PatientID': 'PAT-1004',
  'OrderAssignDetailID': 16,
  'AssignStatusID': 1,
  'UserID': 17,
  'UserRosterID': 1,
  'Status': 'Assigned',
  'Priority': 'High',
  'VisitType': 'Clinic',
  'Title': 'Mr',
  'FirstName': 'Rakul',
  'MiddleName': null,
  'LastName': 'Patil',
  'PatientName': 'Mr Rakul  Patil',
  'Age': '34 Years',
  'Gender': 'Male',
  'photoUrl': null,
  'MobileNumber': '9876501234',
  'AddressLine': 'CIDCO',
  'City': 'Aurangabad',
  'Pincode': '431001',
  'Latitude': 19.8762,
  'Longitude': 75.3433,
  'Address': 'CIDCO, Aurangabad, 431001',
  'Clinic': 'Chhatrapati Sambhajinagar GP 1',
  'SlotDate': '2026-09-02T10:54:01.74',
  'SlotStartTime': '09:00:00',
  'SlotEndTime': '09:30:00',
  'DistanceInKM': null,
  'FastingRequired': 'Fasting Required',
  'Tests': [
    {
      'OrderID': 'TEST-ORD-20260901-005',
      'TestID': 1,
      'TestName': 'Free T4',
      'SampleTypeName': 'Serum',
      'TubeId': 3,
      'TubeContent': 'Plain Tube',
      'FastingRequired': 'Fasting Not Required',
    },
  ],
};

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => Get.reset());

  group('PatientQueueService.fetchAssignedPatients', () {
    test('treats a "No record found" Fail response as an empty queue', () async {
      final service = _buildService(binding, {
        'status': 'Fail',
        'message': 'No record found',
        'output': null,
      });

      final result = await service.fetchAssignedPatients(userId: '17');

      expect(result, isEmpty);
    });

    test('parses a single order returned as a map', () async {
      final service = _buildService(binding, {
        'status': 'Success',
        'message': 'Order details',
        'output': _sampleOutput(),
      });

      final result = await service.fetchAssignedPatients(userId: '17');

      expect(result, hasLength(1));
      expect(result.first.orderId, 'TEST-ORD-20260901-005');
      expect(result.first.name, 'Mr Rakul Patil'); // whitespace normalised
      expect(result.first.visitType.name, 'clinic');
      expect(result.first.tests, ['Free T4']);
      expect(result.first.tubes, hasLength(1));
      expect(result.first.tubes.first.label, '1 Plain Tube');
    });

    test('parses a list of orders', () async {
      final service = _buildService(binding, {
        'status': 'Success',
        'message': 'Order details',
        'output': [
          {
            'SampleCollectionOrderID': 33,
            'OrderID': 'TEST-ORD-1',
            'PatientID': 'P1',
            'FirstName': 'A',
            'PatientName': 'A',
            'Status': 'Assigned',
            'Priority': 'High',
            'VisitType': 'Home',
            'Tests': <Map<String, dynamic>>[],
          },
          {
            'SampleCollectionOrderID': 34,
            'OrderID': 'TEST-ORD-2',
            'PatientID': 'P2',
            'FirstName': 'B',
            'PatientName': 'B',
            'Status': 'Assigned',
            'Priority': 'Normal',
            'VisitType': 'Clinic',
            'Tests': <Map<String, dynamic>>[],
          },
        ],
      });

      final result = await service.fetchAssignedPatients(userId: '17');

      expect(result, hasLength(2));
      expect(result.map((p) => p.orderId), ['TEST-ORD-1', 'TEST-ORD-2']);
    });

    test('parses a "Collect" status as a LIS-sync-failed ("Action Needed") order',
        () async {
      final service = _buildService(binding, {
        'status': 'Success',
        'message': 'Order details',
        'output': {
          ..._sampleOutput(),
          'OrderID': 'TEST-ORD-SYNC',
          'Status': 'Collect',
        },
      });

      final result = await service.fetchAssignedPatients(userId: '17');

      expect(result, hasLength(1));
      final patient = result.first;
      expect(patient.status, PatientStatus.collect);
      // Treated as LIS sync failed — needs a manual "Sync to LIS" action,
      // never as a terminal/completed state.
      expect(patient.status.isLisSyncFailed, isTrue);
      expect(patient.status.needsDishaSync, isTrue);
      expect(patient.status.isTerminal, isFalse);
      // Name + basic details stay intact on the queue card.
      expect(patient.name, 'Mr Rakul Patil');
      expect(patient.orderId, 'TEST-ORD-SYNC');
    });

    test('throws PatientQueueException for a genuine server failure', () async {
      final service = _buildService(binding, {
        'status': 'Fail',
        'message': 'Internal server error',
        'output': null,
      });

      expect(
        () => service.fetchAssignedPatients(userId: '17'),
        throwsA(isA<PatientQueueException>()),
      );
    });
  });
}