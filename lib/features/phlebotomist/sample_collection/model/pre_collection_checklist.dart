enum ChecklistDataType { yesNo, dateTime, unknown }

extension ChecklistDataTypeParsing on String {
  ChecklistDataType toChecklistDataType() {
    // Normalize: trim whitespace, lowercase, strip internal spaces so
    // "Y/N", "y / n", "YN" etc. all match. The backend has been observed
    // sending the yes/no marker as either "String" (insert-echo payload)
    // or "Y/N" (rich GET payload) — both must map to yesNo.
    final normalized = trim().toLowerCase().replaceAll(' ', '');
    switch (normalized) {
      case 'string':
      case 'y/n':
      case 'yn':
        return ChecklistDataType.yesNo;
      case 'datetime':
        return ChecklistDataType.dateTime;
      default:
        return ChecklistDataType.unknown;
    }
  }
}

class ChecklistItem {
  ChecklistItem({
    required this.checklistId,
    required this.checklistName,
    required this.dataType,
    required this.dataValueHint,
    required this.isFastingReq,
    required this.value,
    required this.rawJson,
    this.testName,
    this.fastingMinTime,
    this.fastingMaxTime,
    this.fastingDurationIn,
  });

  final int checklistId;
  final String checklistName;
  final ChecklistDataType dataType;
  final String dataValueHint;
  final bool isFastingReq;
  String value;

  /// The exact object this item was built from, kept verbatim so the
  /// submit payload can echo every field the API sent (ChecklistName,
  /// ChecklistDataType, ChecklistDataValue, IsFastingReq, TestID, ...)
  /// with only ChecklistValue overwritten — instead of us re-declaring
  /// and re-typing each field ourselves and risking one falling out of
  /// sync with whatever the backend adds later.
  final Map<String, dynamic> rawJson;

  final String? testName;
  final double? fastingMinTime;
  final double? fastingMaxTime;
  final String? fastingDurationIn;

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    final rawValue = (json['ChecklistValue'] ?? '0').toString().trim();
    return ChecklistItem(
      checklistId: json['ChecklistID'] as int,
      checklistName: json['ChecklistName'] as String? ?? '',
      dataType:
      (json['ChecklistDataType'] as String? ?? '').toChecklistDataType(),
      dataValueHint: json['ChecklistDataValue'] as String? ?? '',
      isFastingReq: json['IsFastingReq'] as bool? ?? false,
      value: (rawValue.isEmpty || rawValue == '0') ? '' : rawValue,
      rawJson: json,
      testName: json['TestName'] as String?,
      fastingMinTime: (json['FastingMinTime'] as num?)?.toDouble(),
      fastingMaxTime: (json['FastingMaxTime'] as num?)?.toDouble(),
      fastingDurationIn: json['FastingDurationIN'] as String?,
    );
  }
}

/// One out-of-window result for a single fasting-linked test.
class MealTimeConflict {
  const MealTimeConflict({
    required this.checklistId,
    required this.label,
    required this.hoursSinceMeal,
    required this.minHours,
    required this.maxHours,
  });
  final int checklistId;
  final String label;
  final double hoursSinceMeal;
  final double minHours;
  final double maxHours;
}

class ChecklistAnswer {
  ChecklistAnswer({required this.checklistId, required this.checklistValue});

  final int checklistId;
  final String checklistValue;

  // NOTE: the API doc's example body shows `"ChecklistValue": 0` (a bare
  // number), while the GET response returns ChecklistValue as a *string*
  // ("0"). Sending it back as a string here to match the GET shape — if
  // the backend rejects that, switch this to an int/dynamic and confirm
  // with whoever owns the endpoint which shape POST actually expects.
  Map<String, dynamic> toJson() => {
    'ChecklistID': checklistId,
    'ChecklistValue': checklistValue,
  };
}