import 'dart:math';

/// Raw test line from the API — kept intact so it can be re-sent in the
/// accept payload's `listTestDetails`, not just flattened for display.
class OrderTest {
  final int testId;
  final String testName;
  final String? sampleTypeName;
  final int? tubeId;
  final String? tubeContent;
  final String? fastingRequired;

  const OrderTest({
    required this.testId,
    required this.testName,
    this.sampleTypeName,
    this.tubeId,
    this.tubeContent,
    this.fastingRequired,
  });

  factory OrderTest.fromJson(Map<String, dynamic> json) {
    return OrderTest(
      testId: (json['TestID'] as num?)?.toInt() ?? 0,
      testName: json['TestName'] as String? ?? '',
      sampleTypeName: json['SampleTypeName'] as String?,
      tubeId: (json['TubeId'] as num?)?.toInt(),
      tubeContent: json['TubeContent'] as String?,
      fastingRequired: json['FastingRequired'] as String?,
    );
  }
}

enum VisitType { home, clinic }

enum PatientStatus {
  assigned,
  pending,
  accepted,

  /// Phlebotomist tapped "Start Route" — GPS tracking active, on the way
  /// to the patient.
  inRoute,
  inProgress,
  arrived,
  sampleCollectionStarted,
  sampleCollected,

  /// Sample(s) were collected but the push to LIS (Disha) failed — the
  /// order is stuck in "collect" until it is manually re-synced.
  collect,
  completed,
  cancelled,
  failed,
  rescheduled,
  unableToCollect,
  rejected,
}

enum PriorityLevel { normal, high, urgent }

extension PatientStatusX on PatientStatus {
  bool get isActionable =>
      this == PatientStatus.assigned ||
      this == PatientStatus.pending ||
      this == PatientStatus.accepted ||
      this == PatientStatus.rescheduled;

  /// A "collect" order means the collection itself is done but the LIS
  /// (Disha) sync failed — it still requires manual intervention.
  bool get isLisSyncFailed => this == PatientStatus.collect;

  /// Shortcut for the queue's "needs attention / sync to LIS" state.
  bool get needsDishaSync => this == PatientStatus.collect;

  bool get isTerminal =>
      this == PatientStatus.completed ||
      this == PatientStatus.cancelled ||
      this == PatientStatus.failed ||
      this == PatientStatus.rejected ||
      this == PatientStatus.unableToCollect;
}

class TubeRequirement {
  final String type;
  final int count;

  const TubeRequirement({required this.type, required this.count});

  String get label => '$count $type';
}

class AssignedPatient {
  // Identifiers needed later for the accept API body
  final int sampleCollectionOrderId;
  final String patientId;
  final int? orderAssignDetailId;
  final int? assignStatusId;
  final int? userId;

  final String orderId; // OrderID for display
  final String? omsOrderId; // OrderID for display
  final String? title;
  final String firstName;
  final String? middleName;
  final String? lastName;
  final String name; // PatientName, display-ready
  final int? userRosterId;

  final int? age;
  final String? gender;
  final String? avatarUrl;

  final VisitType visitType;
  final PatientStatus status;
  final PriorityLevel priority;

  final DateTime? slotDateTime;
  final bool isFastingRequired;

  final String? address;
  final String? clinic;
  final String? phone;
  final double? distanceKm;

  // Destination coordinates for the en-route map — the patient's address
  // geocoded by the backend (Latitude/Longitude on the order payload).
  final double? destinationLat;
  final double? destinationLng;

  final List<String> tests; // display strings
  final List<OrderTest> rawTests; // kept for accept payload
  final List<TubeRequirement> tubes;

  final String? notes;

  const AssignedPatient({
    required this.sampleCollectionOrderId,
    required this.patientId,
    this.orderAssignDetailId,
    this.assignStatusId,
    this.userId,
    required this.orderId,
    this.omsOrderId,
    this.userRosterId,
    this.title,
    required this.firstName,
    this.middleName,
    this.lastName,
    required this.name,
    this.age,
    this.gender,
    this.avatarUrl,
    required this.visitType,
    required this.status,
    this.priority = PriorityLevel.normal,
    this.slotDateTime,
    this.isFastingRequired = false,
    this.address,
    this.clinic,
    this.phone,
    this.distanceKm,
    this.destinationLat,
    this.destinationLng,
    this.tests = const [],
    this.rawTests = const [],
    this.tubes = const [],
    this.notes,
  });

  /// The queue's `id` used everywhere in the UI is now the real
  /// SampleCollectionOrderID, stringified — kept as a getter so the rest
  /// of the controller/view code (which works with String ids) doesn't
  /// need to change.
  String get id => sampleCollectionOrderId.toString();

  AssignedPatient copyWith({PatientStatus? status, PriorityLevel? priority}) {
    return AssignedPatient(
      sampleCollectionOrderId: sampleCollectionOrderId,
      patientId: patientId,
      orderAssignDetailId: orderAssignDetailId,
      assignStatusId: assignStatusId,
      userId: userId,
      orderId: orderId,
      title: title,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      name: name,
      age: age,
      gender: gender,
      avatarUrl: avatarUrl,
      visitType: visitType,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      slotDateTime: slotDateTime,
      isFastingRequired: isFastingRequired,
      address: address,
      clinic: clinic,
      phone: phone,
      distanceKm: distanceKm,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      tests: tests,
      rawTests: rawTests,
      tubes: tubes,
      notes: notes,
    );
  }

  static PatientStatus _parseStatus(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'assigned':
        return PatientStatus.assigned;
      case 'pending':
        return PatientStatus.pending;
      case 'accepted':
        return PatientStatus.accepted;
      case 'inroute':
      case 'in route':
      case 'in_route':
        return PatientStatus.inRoute;
      case 'inprogress':
      case 'in progress':
        return PatientStatus.inProgress;
      case 'arrived':
        return PatientStatus.arrived;
      case 'samplecollectionstarted':
        return PatientStatus.sampleCollectionStarted;
      case 'samplecollected':
        return PatientStatus.sampleCollected;
      case 'collected':
      case 'collect':
        // Sample collected but LIS sync failed — needs a manual re-sync.
        return PatientStatus.collect;
      case 'completed':
        return PatientStatus.completed;
      case 'cancelled':
      case 'canceled':
        return PatientStatus.cancelled;
      case 'failed':
        return PatientStatus.failed;
      case 'rescheduled':
        return PatientStatus.rescheduled;
      case 'rejected':
      case 'Rejected':
        return PatientStatus.rejected;
      case 'unabletocollect':
        return PatientStatus.unableToCollect;
      default:
        return PatientStatus.assigned;
    }
  }

  static PriorityLevel _parsePriority(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'urgent':
        return PriorityLevel.urgent;
      case 'high':
        return PriorityLevel.high;
      default:
        return PriorityLevel.normal;
    }
  }

  static int? _parseAge(String? raw) {
    if (raw == null) return null;
    final match = RegExp(r'\d+').firstMatch(raw);
    return match != null ? int.tryParse(match.group(0)!) : null;
  }

  static DateTime? _parseSlot(String? date, String? time) {
    if (date == null) return null;
    try {
      final datePart = DateTime.parse(date); // handles the trailing time too
      if (time == null || time.isEmpty) return datePart;
      final t = time.split(':').map(int.parse).toList();
      return DateTime(
        datePart.year,
        datePart.month,
        datePart.day,
        t.isNotEmpty ? t[0] : 0,
        t.length > 1 ? t[1] : 0,
        t.length > 2 ? t[2] : 0,
      );
    } catch (_) {
      return null;
    }
  }

  static bool _parseFasting(String? raw) {
    final v = (raw ?? '').toLowerCase();
    if (v.contains('not')) return false;
    return v.contains('required');
  }

  /// Groups the raw test list's tube info into the summary chips shown
  /// on the card (e.g. "2 Plain Tube").
  static List<TubeRequirement> _buildTubes(List<OrderTest> tests) {
    final counts = <String, int>{};
    for (final t in tests) {
      final label = t.tubeContent?.trim();
      if (label == null || label.isEmpty) continue;
      counts[label] = (counts[label] ?? 0) + 1;
    }
    return counts.entries
        .map((e) => TubeRequirement(type: e.key, count: e.value))
        .toList();
  }

  factory AssignedPatient.fromJson(Map<String, dynamic> json) {
    final rawTests =
        (json['Tests'] as List?)
            ?.map((e) => OrderTest.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <OrderTest>[];
    final puneLocation = _randomPuneLocation();

    return AssignedPatient(
      sampleCollectionOrderId:
          (json['SampleCollectionOrderID'] as num?)?.toInt() ?? 0,
      patientId: json['PatientID'] as String? ?? '',

      orderAssignDetailId: (json['OrderAssignDetailID'] as num?)?.toInt(),
      assignStatusId: (json['AssignStatusID'] as num?)?.toInt(),
      userId: (json['UserID'] as num?)?.toInt(),
      orderId: json['OrderID'] as String? ?? '',
      omsOrderId: json['OMSOrderID'] as String?,
      userRosterId: json['UserRosterID'] ?? 0,
      title: json['Title'] as String?,
      firstName: json['FirstName'] as String? ?? '',
      middleName: json['MiddleName'] as String?,
      lastName: json['LastName'] as String?,
      name:
          (json['PatientName'] as String?)?.trim().replaceAll(
            RegExp(r'\s+'),
            ' ',
          ) ??
          'Unknown Patient',
      age: _parseAge(json['Age'] as String?),
      gender: json['Gender'] as String?,
      avatarUrl: json['photoUrl'] as String?,
      visitType: (json['VisitType'] as String?)?.toLowerCase() == 'clinic'
          ? VisitType.clinic
          : VisitType.home,
      status: (() {
        final isRoute = (json['IsRoute'] as String?)?.trim().toLowerCase();

        if (isRoute == 'start') {
          return PatientStatus.inRoute;
        }

        if (isRoute == 'end') {
          return PatientStatus.arrived;
        }

        return _parseStatus(json['Status'] as String?);
      })(),

      priority: _parsePriority(json['Priority'] as String?),
      slotDateTime: _parseSlot(
        json['SlotDate'] as String?,
        json['SlotStartTime'] as String?,
      ),
      isFastingRequired: _parseFasting(json['FastingRequired'] as String?),
      address: json['Address'] as String? ?? json['AddressLine'] as String?,
      clinic: json['Clinic'] as String?,
      phone: json['MobileNumber'] as String?,
      distanceKm: (json['DistanceInKM'] as num?)?.toDouble(),
      destinationLat:
      (json['Latitude'] as num?)?.toDouble() ?? puneLocation.lat,

      destinationLng:
      (json['Longitude'] as num?)?.toDouble() ?? puneLocation.lng,
      tests: rawTests.map((t) => t.testName).toList(),
      rawTests: rawTests,
      tubes: _buildTubes(rawTests),
      notes: null,
    );
  }


  // for testing purpose only remove this latter
  static ({double lat, double lng}) _randomPuneLocation() {
    final random = Random();

    return (
    lat: 18.45 + random.nextDouble() * (18.65 - 18.45),
    lng: 73.75 + random.nextDouble() * (73.95 - 73.75),
    );
  }
}
