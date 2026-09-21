class ConnectorListResponse {
  final String status;
  final String message;
  final List<Connector>? output;

  ConnectorListResponse({
    required this.status,
    required this.message,
    this.output,
  });

  factory ConnectorListResponse.fromJson(Map<String, dynamic> json) {
    return ConnectorListResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      output: json['output'] != null
          ? (json['output'] as List)
          .map((item) => Connector.fromJson(item))
          .toList()
          : null,
    );
  }

  bool get isSuccess => status.toLowerCase() == 'success';
}

class Connector {
  final int userId;
  final int facilityCode;
  final String facilityName;
  final String ward;
  final String userName;
  final String fType;

  Connector({
    required this.userId,
    required this.facilityCode,
    required this.facilityName,
    required this.ward,
    required this.userName,
    required this.fType,
  });

  factory Connector.fromJson(Map<String, dynamic> json) {
    return Connector(
      userId: _asInt(json['USERID'] ?? json['userid']),
      facilityCode: _asInt(json['FacilityCode'] ?? json['facilitycode']),
      facilityName:
      (json['FacilityName'] ?? json['Facilityname'] ?? '').toString(),
      // Not present in the current API response — defaults to empty.
      ward: (json['Ward'] ?? json['ward'] ?? '').toString(),
      userName: (json['UserName'] ?? json['Username'] ?? '')
          .toString()
          .trim(),
      fType: (json['FType'] ?? json['ftype'] ?? '').toString(),
    );
  }

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'USERID': userId,
      'FacilityCode': facilityCode,
      'FacilityName': facilityName,
      'Ward': ward,
      'UserName': userName,
      'FType': fType,
    };
  }
}
