/// Models for the Assigned Patients (Patient Queue) module.
///
/// Kept intentionally free of any UI/Flutter-widget concerns — colors,
/// icons, and labels for these enums are resolved in the presentation
/// layer (see `widgets/status_badge.dart`, `widgets/visit_type_badge.dart`)
/// so this file can be reused by non-UI code (services, tests) safely.

/// Where the sample collection happens.
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
}
