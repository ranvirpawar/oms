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
  inProgress,
  arrived,
  sampleCollectionStarted,
  sampleCollected,
  completed,
  cancelled,
  failed,
  rescheduled,
  unableToCollect,
}

enum PriorityLevel { normal, high, urgent }

extension PatientStatusX on PatientStatus {
  bool get isActionable =>
      this == PatientStatus.assigned ||
          this == PatientStatus.pending ||
          this == PatientStatus.accepted;

  bool get isTerminal =>
      this == PatientStatus.completed ||
          this == PatientStatus.cancelled ||
          this == PatientStatus.failed ||
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
  final int patientId;
  final int? orderAssignDetailId;
  final int? assignStatusId;
  final int? userId;

  final String orderId;      // OMSOrderID / OrderID for display
  final String? title;
  final String firstName;
  final String? middleName;
  final String? lastName;
  final String name;         // PatientName, display-ready

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

  final List<String> tests;        // display strings
  final List<OrderTest> rawTests;  // kept for accept payload
  final List<TubeRequirement> tubes;

  final String? notes;

  const AssignedPatient({
    required this.sampleCollectionOrderId,
    required this.patientId,
    this.orderAssignDetailId,
    this.assignStatusId,
    this.userId,
    required this.orderId,
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
      case 'inprogress':
      case 'in progress':
        return PatientStatus.inProgress;
      case 'arrived':
        return PatientStatus.arrived;
      case 'samplecollectionstarted':
        return PatientStatus.sampleCollectionStarted;
      case 'samplecollected':
        return PatientStatus.sampleCollected;
      case 'completed':
        return PatientStatus.completed;
      case 'cancelled':
      case 'canceled':
        return PatientStatus.cancelled;
      case 'failed':
        return PatientStatus.failed;
      case 'rescheduled':
        return PatientStatus.rescheduled;
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
    final rawTests = (json['Tests'] as List?)
        ?.map((e) => OrderTest.fromJson(e as Map<String, dynamic>))
        .toList() ??
        const <OrderTest>[];

    return AssignedPatient(
      sampleCollectionOrderId:
      (json['SampleCollectionOrderID'] as num?)?.toInt() ?? 0,
      patientId: (json['PatientID'] is String)
          ? (int.tryParse(
          RegExp(r'\d+').firstMatch(json['PatientID'] as String)?.group(0) ?? '0') ??
          0)
          : (json['PatientID'] as num?)?.toInt() ?? 0,
      orderAssignDetailId: (json['OrderAssignDetailID'] as num?)?.toInt(),
      assignStatusId: (json['AssignStatusID'] as num?)?.toInt(),
      userId: (json['UserID'] as num?)?.toInt(),
      orderId:
      json['OMSOrderID'] as String? ?? json['OrderID'] as String? ?? '',
      title: json['Title'] as String?,
      firstName: json['FirstName'] as String? ?? '',
      middleName: json['MiddleName'] as String?,
      lastName: json['LastName'] as String?,
      name: (json['PatientName'] as String?)?.trim().replaceAll(
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
      status: _parseStatus(json['Status'] as String?),
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
      tests: rawTests.map((t) => t.testName).toList(),
      rawTests: rawTests,
      tubes: _buildTubes(rawTests),
      notes: null,
    );
  }
}

/*/// Where the sample collection happens.
enum VisitType { home, clinic }

/// Full lifecycle of an assignment. Not all of these are necessarily
/// surfaced as distinct UI treatments today, but the model supports the
/// entire lifecycle so the UI can be extended without a data-model change.
enum PatientStatus {
  assigned,
  pending,
  accepted,
  inProgress,
  arrived,
  sampleCollectionStarted,
  sampleCollected,
  completed,
  cancelled,
  failed,
  rescheduled,
  unableToCollect,
}

/// Visit priority — drives sort order and the priority indicator.
enum PriorityLevel { normal, high, urgent }

extension PatientStatusX on PatientStatus {
  /// Whether this status still requires phlebotomist action.
  bool get isActionable =>
      this == PatientStatus.assigned ||
      this == PatientStatus.pending ||
      this == PatientStatus.accepted;

  /// Whether the queue item is in a finished / non-actionable state.
  bool get isTerminal =>
      this == PatientStatus.completed ||
      this == PatientStatus.cancelled ||
      this == PatientStatus.failed ||
      this == PatientStatus.unableToCollect;
}

/// A single sample tube requirement, e.g. "2 SST", "1 EDTA".
class TubeRequirement {
  final String type; // SST, EDTA, Fluoride, etc.
  final int count;

  const TubeRequirement({required this.type, required this.count});

  String get label => '$count $type';

  factory TubeRequirement.fromJson(Map<String, dynamic> json) {
    return TubeRequirement(
      type: json['type'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {'type': type, 'count': count};
}

/// A patient assignment as shown in the queue.
///
/// Several fields are nullable on purpose — the API/backend is not always
/// guaranteed to send complete data (missing address, missing phone,
/// missing slot time, etc.), and the UI must degrade gracefully rather
/// than crash or show "null".
class AssignedPatient {
  final String id;
  final String orderId;
  final String name;
  final int? age;
  final String? gender;
  final String? avatarUrl;

  final VisitType visitType;
  final PatientStatus status;
  final PriorityLevel priority;

  final DateTime? slotDateTime;
  final bool isFastingRequired;

  final String? address;
  final String? phone;
  final double? distanceKm;

  final List<String> tests;
  final List<TubeRequirement> tubes;

  final String? notes;

  const AssignedPatient({
    required this.id,
    required this.orderId,
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
    this.phone,
    this.distanceKm,
    this.tests = const [],
    this.tubes = const [],
    this.notes,
  });

  AssignedPatient copyWith({
    PatientStatus? status,
    PriorityLevel? priority,
  }) {
    return AssignedPatient(
      id: id,
      orderId: orderId,
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
      phone: phone,
      distanceKm: distanceKm,
      tests: tests,
      tubes: tubes,
      notes: notes,
    );
  }

  int get totalTubeCount => tubes.fold(0, (sum, t) => sum + t.count);

  factory AssignedPatient.fromJson(Map<String, dynamic> json) {
    return AssignedPatient(
      id: json['id'] as String,
      orderId: json['orderId'] as String? ?? '',
      name: json['name'] as String? ?? 'Unknown Patient',
      age: (json['age'] as num?)?.toInt(),
      gender: json['gender'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      visitType: (json['visitType'] as String?) == 'clinic'
          ? VisitType.clinic
          : VisitType.home,
      status: PatientStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PatientStatus.assigned,
      ),
      priority: PriorityLevel.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => PriorityLevel.normal,
      ),
      slotDateTime: json['slotDateTime'] != null
          ? DateTime.tryParse(json['slotDateTime'] as String)
          : null,
      isFastingRequired: json['isFastingRequired'] as bool? ?? false,
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      tests: (json['tests'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      tubes: (json['tubes'] as List?)
              ?.map((e) => TubeRequirement.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderId': orderId,
        'name': name,
        'age': age,
        'gender': gender,
        'avatarUrl': avatarUrl,
        'visitType': visitType.name,
        'status': status.name,
        'priority': priority.name,
        'slotDateTime': slotDateTime?.toIso8601String(),
        'isFastingRequired': isFastingRequired,
        'address': address,
        'phone': phone,
        'distanceKm': distanceKm,
        'tests': tests,
        'tubes': tubes.map((t) => t.toJson()).toList(),
        'notes': notes,
      };
}*/
