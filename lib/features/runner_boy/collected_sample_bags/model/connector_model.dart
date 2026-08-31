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
      userId: json['userid'] ?? 0,
      facilityCode: json['facilitycode'] ?? 0,
      facilityName: json['Facilityname'] ?? '',
      ward: json['Ward'] ?? '',
      userName: json['Username'] ?? '',
      fType: json['FType'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userid': userId,
      'facilitycode': facilityCode,
      'Facilityname': facilityName,
      'Ward': ward,
      'Username': userName,
      'FType': fType,
    };
  }
}
