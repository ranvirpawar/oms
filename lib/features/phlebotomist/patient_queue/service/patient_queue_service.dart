import 'dart:math';

import '../model/patient_queue_model.dart';



/// Thrown by [PatientQueueService] to represent a recoverable failure
/// (network error, timeout, server error) so the controller can show a
/// proper error state with a retry action instead of an unhandled crash.
class PatientQueueException implements Exception {
  final String message;
  final bool isNetworkError;

  PatientQueueException(this.message, {this.isNetworkError = false});

  @override
  String toString() => message;
}

/// Handles all data access for the Assigned Patients module.
///
/// Currently backed by dummy/in-memory data so the UI can be fully
/// evaluated without the backend. When the real endpoint is ready, only
/// the body of [fetchAssignedPatients] (and the mutation methods) needs to
/// change to call through the project's existing centralized API client,
/// e.g.:
///
/// ```dart
/// class PatientQueueService {
///   final APIClient _apiClient = Get.find<APIClient>();
///
///   Future<List<AssignedPatient>> fetchAssignedPatients() async {
///     final response = await _apiClient.get('/phlebotomist/assigned-patients');
///     return (response.data['patients'] as List)
///         .map((e) => AssignedPatient.fromJson(e))
///         .toList();
///   }
/// }
/// ```
///
/// The rest of the module (controller, view, widgets) only depends on the
/// public method signatures below, so swapping the implementation is a
/// contained change.
class PatientQueueService {
  /// Simulates fetching today's assigned patients.
  ///
  /// [simulateFailure] / [simulateEmpty] are here purely so the UI's error
  /// and empty states can be exercised during development — remove once
  /// the real API is wired up.
  Future<List<AssignedPatient>> fetchAssignedPatients({
    bool simulateFailure = false,
    bool simulateEmpty = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));

    if (simulateFailure) {
      throw PatientQueueException(
        'Unable to load your patient queue. Please check your connection and try again.',
        isNetworkError: true,
      );
    }

    if (simulateEmpty) return const [];

    return _dummyPatients;
  }

  Future<bool> acceptAndStart(String patientId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  Future<bool> startRoute(String patientId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  Future<bool> reject(String patientId, {String? reason}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  Future<bool> reschedule(String patientId, {DateTime? newSlot}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  // ---------------------------------------------------------------------
  // Dummy data — deliberately varied to stress-test the UI: long names,
  // long test lists, missing optional fields, every status/visit-type/
  // priority combination, etc.
  // ---------------------------------------------------------------------
  static final DateTime _today = DateTime.now();

  DateTime _at(int hour, int minute, {int dayOffset = 0}) => DateTime(
        _today.year,
        _today.month,
        _today.day + dayOffset,
        hour,
        minute,
      );

  late final List<AssignedPatient> _dummyPatients = [
    AssignedPatient(
      id: 'p1',
      orderId: 'CY12458',
      name: 'Anita Deshmukh',
      age: 34,
      gender: 'Female',
      visitType: VisitType.home,
      status: PatientStatus.assigned,
      priority: PriorityLevel.urgent,
      slotDateTime: _at(8, 0),
      isFastingRequired: true,
      address: '89, MG Road, Shivaji Nagar, Pune - 411005',
      phone: '9953221340',
      distanceKm: 1.2,
      tests: const ['Thyroid Panel', 'Iron Studies'],
      tubes: const [
        TubeRequirement(type: 'SST', count: 2),
        TubeRequirement(type: 'EDTA', count: 1),
      ],
    ),
    AssignedPatient(
      id: 'p2',
      orderId: 'CY12457',
      name: 'Rohan Gupta',
      age: 36,
      gender: 'Male',
      visitType: VisitType.clinic,
      status: PatientStatus.rescheduled,
      priority: PriorityLevel.normal,
      slotDateTime: _at(7, 30, dayOffset: 1),
      isFastingRequired: true,
      address: 'Clinic 1, Baner, Pune - 411045',
      phone: '9820556781',
      distanceKm: 1.2,
      tests: const ['Lipid Profile', 'CBC'],
      tubes: const [
        TubeRequirement(type: 'SST', count: 4),
        TubeRequirement(type: 'EDTA', count: 3),
      ],
    ),
    AssignedPatient(
      id: 'p3',
      orderId: 'CY76541',
      name: 'Meenal Sharma',
      age: 26,
      gender: 'Female',
      visitType: VisitType.home,
      status: PatientStatus.pending,
      priority: PriorityLevel.high,
      slotDateTime: _at(9, 30, dayOffset: 1),
      isFastingRequired: false,
      address: '18, Maple Heights, Kothrud, Pune - 411038',
      phone: '9850112233',
      distanceKm: 1.2,
      tests: const ['Blood Routine', 'Vitamin D', 'TSH'],
      tubes: const [
        TubeRequirement(type: 'SST', count: 2),
        TubeRequirement(type: 'EDTA', count: 1),
      ],
    ),
    AssignedPatient(
      id: 'p4',
      orderId: 'CY98212',
      name: 'Christopher Alexander Wentworth-Sinclair',
      age: 61,
      gender: 'Male',
      visitType: VisitType.home,
      status: PatientStatus.accepted,
      priority: PriorityLevel.normal,
      slotDateTime: _at(10, 15),
      isFastingRequired: true,
      address:
          'Flat 402, Rosewood Residency, Near Symbiosis College, Viman Nagar, Pune - 411014',
      phone: '9765443210',
      distanceKm: 4.8,
      tests: const [
        'Comprehensive Metabolic Panel',
        'HbA1c',
        'Lipid Profile',
        'Liver Function Test',
        'Kidney Function Test',
      ],
      tubes: const [
        TubeRequirement(type: 'SST', count: 3),
        TubeRequirement(type: 'Fluoride', count: 1),
        TubeRequirement(type: 'EDTA', count: 2),
      ],
    ),
    AssignedPatient(
      id: 'p5',
      orderId: 'CY44190',
      name: 'Imran Sheikh',
      visitType: VisitType.clinic,
      status: PatientStatus.assigned,
      priority: PriorityLevel.normal,
      slotDateTime: _at(11, 0),
      isFastingRequired: false,
      phone: '9922334455',
      // no address on purpose — clinic visits may not need one
      distanceKm: 0.4,
      tests: const ['CBC'],
      tubes: const [TubeRequirement(type: 'EDTA', count: 1)],
    ),
    AssignedPatient(
      id: 'p6',
      orderId: 'CY55023',
      name: 'Kavya Reddy',
      age: 8,
      gender: 'Female',
      visitType: VisitType.home,
      status: PatientStatus.inProgress,
      priority: PriorityLevel.high,
      slotDateTime: _at(9, 0),
      isFastingRequired: false,
      address: '22, Green Valley Society, Wakad, Pune - 411057',
      phone: '9876501234',
      distanceKm: 2.6,
      tests: const ['Complete Blood Count', 'Malaria Antigen'],
      tubes: const [TubeRequirement(type: 'EDTA', count: 1)],
    ),
    AssignedPatient(
      id: 'p7',
      orderId: 'CY33871',
      name: 'Suresh Patil',
      age: 58,
      gender: 'Male',
      visitType: VisitType.home,
      status: PatientStatus.completed,
      priority: PriorityLevel.normal,
      slotDateTime: _at(6, 45),
      isFastingRequired: true,
      address: '5, Sadashiv Peth, Pune - 411030',
      phone: '9823456712',
      distanceKm: 3.1,
      tests: const ['Fasting Blood Sugar', 'Lipid Profile'],
      tubes: const [TubeRequirement(type: 'SST', count: 2)],
    ),
    AssignedPatient(
      id: 'p8',
      orderId: 'CY19004',
      name: 'Priya Nair',
      age: 29,
      gender: 'Female',
      visitType: VisitType.clinic,
      status: PatientStatus.cancelled,
      priority: PriorityLevel.normal,
      slotDateTime: _at(12, 30),
      isFastingRequired: false,
      address: 'Clinic 2, Hinjewadi, Pune - 411057',
      phone: '9911223344',
      distanceKm: 6.3,
      tests: const ['Vitamin B12'],
      tubes: const [TubeRequirement(type: 'SST', count: 1)],
    ),
    AssignedPatient(
      id: 'p9',
      orderId: 'CY29981',
      name: 'Deepak Kulkarni',
      // age intentionally missing
      visitType: VisitType.home,
      status: PatientStatus.failed,
      priority: PriorityLevel.normal,
      slotDateTime: _at(13, 0),
      isFastingRequired: false,
      address: '77, Aundh Road, Pune - 411007',
      // phone intentionally missing
      distanceKm: 5.5,
      tests: const ['Urine Routine'],
      tubes: const [TubeRequirement(type: 'Sterile Container', count: 1)],
      notes: 'Patient unreachable after 2 attempts.',
    ),
    AssignedPatient(
      id: 'p10',
      orderId: 'CY67230',
      name: 'Farhan Ansari',
      age: 41,
      gender: 'Male',
      visitType: VisitType.clinic,
      status: PatientStatus.assigned,
      priority: PriorityLevel.urgent,
      slotDateTime: null, // missing appointment time on purpose
      isFastingRequired: true,
      address: 'Clinic 3, Kharadi, Pune - 411014',
      phone: '9090011223',
      distanceKm: 0.9,
      tests: const ['Glucose Tolerance Test'],
      tubes: const [TubeRequirement(type: 'Fluoride', count: 3)],
    ),
  ];
}

/// Utility to reshuffle dummy IDs when simulating "a new assignment
/// appears" during manual/dev testing.
String generateDummyId() => 'p${Random().nextInt(9999)}';
