enum ChecklistDataType { yesNo, dateTime, unknown }

extension ChecklistDataTypeParsing on String {
  ChecklistDataType toChecklistDataType() {
    switch (toLowerCase()) {
      case 'string':
        return ChecklistDataType.yesNo;
      case 'datetime':
        return ChecklistDataType.dateTime;
      default:
        return ChecklistDataType.unknown;
    }
  }
}

/// One row of `/collection-checklist`. `value` is mutable and mutated
/// in-place by the controller as the phlebotomist answers, then read back
/// out when building the submit payload.
class ChecklistItem {
  ChecklistItem({
    required this.checklistId,
    required this.checklistName,
    required this.dataType,
    required this.dataValueHint,
    required this.isFastingReq,
    required this.value,
  });

  final int checklistId;
  final String checklistName;
  final ChecklistDataType dataType;

  /// Server hint for how to render/format the value, e.g. "Y/N" or
  /// "dd-mm-yyyy hh:mm". Not used for validation, just UI guidance.
  final String dataValueHint;
  final bool isFastingReq;

  /// Current answer. Empty string = unanswered. For yes/no this is 'Y' or
  /// 'N'; for datetime it's formatted per [dataValueHint].
  String value;

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    final rawValue = json['ChecklistValue'] as String? ?? '0';
    return ChecklistItem(
      checklistId: json['ChecklistID'] as int,
      checklistName: json['ChecklistName'] as String? ?? '',
      dataType:
      (json['ChecklistDataType'] as String? ?? '').toChecklistDataType(),
      dataValueHint: json['ChecklistDataValue'] as String? ?? '',
      isFastingReq: json['IsFastingReq'] as bool? ?? false,
      // Server sends "0" as a not-yet-answered placeholder, not a real value.
      value: rawValue == '0' ? '' : rawValue,
    );
  }
}

/// Outgoing answer for one checklist row.
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