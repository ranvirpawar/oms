class AssignRejectedReasonOption {
  final int assignRejectReasonId;
  final String assignRejectReasonShortCode;
  final String assignRejectReasonName;

  AssignRejectedReasonOption({
    required this.assignRejectReasonId,
    required this.assignRejectReasonShortCode,
    required this.assignRejectReasonName,
  });

  factory AssignRejectedReasonOption.fromJson(Map<String, dynamic> json) {
    return AssignRejectedReasonOption(
      assignRejectReasonId: json['AssignRejectReasonID'] ?? 0,
      assignRejectReasonShortCode:
      json['AssignRejectReasonShortCode'] ?? '',
      assignRejectReasonName:
      json['AssignRejectReasonName'] ?? '',
    );
  }
}