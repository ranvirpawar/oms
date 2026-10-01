import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lifenity_connect/features/phlebotomist/patient_queue/model/patient_queue_model.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/controller/order_confirmation_controller.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/controller/sample_collection_controller.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/model/barcode_formatter.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/model/pre_collection_checklist.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/model/sample_collection_models.dart';
import 'package:lifenity_connect/features/phlebotomist/sample_collection/service/sample_collection_service.dart';
import 'package:lifenity_connect/network/api_client.dart';
import 'package:lifenity_connect/network/session_coordinator.dart';
import 'package:lifenity_connect/services/auth_manager.dart';

final _patient = AssignedPatient.fromJson({
  'OrderID': 'ORD-TEST',
  'SampleCollectionOrderID': 75,
  'OrderStatusID': 5,
  'Tests': <Map<String, dynamic>>[],
});
final _reason = IncompleteReasonOption(
  reasonId: 2,
  reason: 'Patient not fasting',
);
final _schedule = TestIncompleteInfo(
  reason: _reason,
  appointmentDate: DateTime(2026, 10, 3),
  slotId: 8,
  slotLabel: '08:00 – 08:30',
);
TestInfo _test(int id, List<int> tubes) => TestInfo(
  testId: id,
  testCode: 'T$id',
  testName: 'Test $id',
  tubeTypes: [
    for (final tube in tubes)
      TubeTypeInfo(tubeTypeId: tube, tubeType: 'Tube $tube'),
  ],
);

class _RecordingService extends SampleCollectionService {
  SampleCollectionPayload? payload;
  @override
  Future<bool> checkBarcodeAvailability(String barcode) async => true;
  @override
  Future<OrderConfirmationDetails> fetchOrderDetails({
    required String orderId,
    required String userId,
  }) async => OrderConfirmationDetails.fromJson({
    'orderId': orderId,
    'sampleRequirements': [
      {
        'sampleTypeId': 2,
        'sampleType': 'Blood',
        'tests': [
          {
            'testId': 101,
            'testName': 'Fasting test',
            'tubeTypes': [
              {'tubeTypeId': 5, 'tubeType': 'EDTA'},
            ],
          },
          {
            'testId': 102,
            'testName': 'Other test',
            'tubeTypes': [
              {'tubeTypeId': 5, 'tubeType': 'EDTA'},
            ],
          },
        ],
      },
      for (final id in [3, 4])
        {
          'sampleTypeId': id,
          'sampleType': 'Sample $id',
          'tests': [
            {
              'testId': 101,
              'testName': 'Fasting test',
              'tubeTypes': [
                {'tubeTypeId': 6, 'tubeType': 'Other tube'},
              ],
            },
          ],
        },
    ],
  });
  @override
  Future<bool> submitSampleCollection(SampleCollectionPayload value) async {
    payload = value;
    // Exercise the saved-but-LIS-failed path without refreshing a real bag.
    throw SampleCollectionException(
      'Saved, LIS unavailable',
      isLisSyncFailure: true,
    );
  }
}

class _CollectionController extends SampleCollectionController {
  _CollectionController(_RecordingService service)
    : super(
        orderId: 'ORD-TEST',
        assignedPatient: _patient,
        fastingIncompleteTests: {101: _schedule},
        service: service,
      );
  @override
  bool get hasOpenBag => true;
  @override
  int get activeBagId => 54;
  @override
  int get activeSessionId => 75;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Get.reset();
    Get.put<APIClient>(
      APIClient(dio: Dio(), sessionManager: SessionCoordinator(AuthManager())),
    );
  });
  tearDown(Get.reset);

  test(
    'test tube counts preserve shared types, barcode and manual add/remove',
    () {
      final entry = SampleBarcodeEntry(
        sampleTypeId: 2,
        sampleType: 'Blood',
        volumeRequiredMl: '',
        tests: [
          _test(101, [5, 6, 5]),
          _test(102, [5]),
        ],
      );
      addTearDown(entry.dispose);
      entry.barcodeController.text = 'JAA55584888';
      expect(entry.tubeCount, 2);
      expect(entry.testTubeDetails.map((e) => e.tubeCount), [1, 1, 1]);
      entry.addManualTube(tubeTypeId: 5, tubeType: 'EDTA');
      expect(entry.tubeCount, 3);
      expect(entry.testTubeDetails.map((e) => e.tubeCount), [2, 1, 2]);
      expect(entry.testTubeDetails.first.toJson(), {
        'TestId': 101,
        'SampleTypeID': 2,
        'TubeTypeID': 5,
        'TubeCount': 2,
      });
      expect(entry.barcodeController.text, 'JAA55584888');
      entry.removeManualTube(entry.manualTubes.single.id);
      expect(entry.testTubeDetails.map((e) => e.tubeCount), [1, 1, 1]);
    },
  );

  test(
    'fasting conflicts require per-test reason/date/slot and reset when meal time changes',
    () {
      final controller = OrderConfirmationController(assignedPatient: _patient);
      addTearDown(controller.onClose);
      final mealTime = DateFormat(
        'dd-MM-yyyy HH:mm',
      ).format(DateTime.now().subtract(const Duration(hours: 1)));
      controller.checklistItems.assignAll([
        for (final id in [101, 102])
          ChecklistItem.fromJson({
            'ChecklistID': id,
            'TestID': '$id',
            'IsFastingReq': true,
            'ChecklistDataType': 'DateTime',
            'ChecklistValue': mealTime,
            'FastingMinTime': 8,
            'FastingMaxTime': 12,
          }),
      ]);
      expect(controller.mealTimeConflicts.length, 2);
      controller.fastingAdvisoryAcknowledged.value = true;
      expect(controller.isChecklistComplete, false);
      controller.setFastingIncompleteTest(101, _schedule);
      controller.setFastingIncompleteTest(
        102,
        TestIncompleteInfo(reason: _reason),
      );
      expect(controller.isChecklistComplete, false);
      controller.setFastingIncompleteTest(102, _schedule);
      expect(controller.isChecklistComplete, true);
      controller.checklistItems.add(
        ChecklistItem.fromJson({
          'ChecklistID': 103,
          'ChecklistDataType': 'Y/N',
          'ChecklistValue': '',
        }),
      );
      controller.setChecklistAnswer(103, 'Yes');
      expect(controller.fastingIncompleteTests.length, 2);
      controller.fastingAdvisoryAcknowledged.value = true;
      expect(controller.isChecklistComplete, true);
      controller.setChecklistAnswer(
        101,
        DateFormat(
          'dd-MM-yyyy HH:mm',
        ).format(DateTime.now().subtract(const Duration(hours: 10))),
      );
      expect(controller.fastingIncompleteTests, isEmpty);
      expect(controller.mealTimeConflicts, isEmpty);
      expect(
        controller.checklistItems[0].value,
        controller.checklistItems[1].value,
      );
      expect(controller.isChecklistComplete, true);
    },
  );

  test(
    'checklist selections survive into collection and serialize updated payload',
    () async {
      final service = _RecordingService();
      final controller = _CollectionController(service);
      addTearDown(controller.onClose);
      controller.empId.value = '17';
      await controller.fetchOrderDetails();
      expect(
        controller.sampleEntries[0].testIncompleteMap[101],
        same(_schedule),
      );
      expect(controller.sampleEntries[1].isFullyUnusable, true);
      expect(controller.sampleEntries[2].isFullyUnusable, true);
      final blood = controller.sampleEntries.first;
      blood.barcodeController.text = 'JAA55584888';
      expect(blood.isFullyUnusable, false);
      controller.onBarcodeChanged(
        blood,
        blood.barcodeController.text,
        immediate: true,
      );
      await Future<void>.delayed(Duration.zero);
      expect(blood.isCollected, true);
      expect(blood.testIncompleteMap.keys, [101]);
      controller.addManualTube(blood, tubeTypeId: 5, tubeType: 'EDTA');
      expect(controller.validate(), isNull);
      final result = await controller.submitCollection();
      expect(result?.outcome, SampleSubmissionOutcome.partialLisFailure);
      final json = service.payload!.toJson();
      expect(json['TubeCount'], 2);
      expect(json['OrderStatusCode'], 'PARTIALLY_COLLECTED');
      expect(json['bagId'], 54);
      expect(json['SessionID'], 75);
      expect(json['SampleCollectionDetails'], [
        {'SampleTypeID': 2, 'BarcodeNo': 'JAA55584888'},
      ]);
      expect(json['IncompleteTests'], [
        {
          'TestID': 101,
          'IncompleteReasonID': 2,
          'IncompleteReason': 'Patient not fasting',
          'AppointmentDate': '2026-10-03',
          'SlotID': 8,
        },
      ]);
      expect(json['TestTubeDetails'], [
        for (final id in [101, 102])
          {'TestId': id, 'SampleTypeID': 2, 'TubeTypeID': 5, 'TubeCount': 2},
      ]);
    },
  );
}
