class ResourcesDataResponse {
  final String status;
  final String message;
  final List<ResourcesData> output;

  ResourcesDataResponse({
    required this.status,
    required this.message,
    required this.output,
  });

  factory ResourcesDataResponse.fromJson(Map<String, dynamic> json) {
    return ResourcesDataResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      output: (json['output'] as List<dynamic>?)
          ?.map((e) => ResourcesData.fromJson(e))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'output': output.map((e) => e.toJson()).toList(),
    };
  }
}

class ResourcesData {
  final int userId;
  final String username;
  final String name;
  final String mobNo;
  final String emailId;
  final int desgId;
  final String desgName;
  final int mappedFacility;
  final int visitedFacility;

  ResourcesData({
    required this.userId,
    required this.username,
    required this.name,
    required this.mobNo,
    required this.emailId,
    required this.desgId,
    required this.desgName,
    required this.mappedFacility,
    required this.visitedFacility,
  });

  factory ResourcesData.fromJson(Map<String, dynamic> json) {
    return ResourcesData(
      userId: json['USERID'] ?? 0,
      username: json['USERNAME'] ?? '',
      name: json['Name'] ?? '',
      mobNo: json['MOBNO'] ?? '',
      emailId: json['EMAILID'] ?? '',
      desgId: json['DesgId'] ?? 0,
      desgName: json['DesgName'] ?? '',
      mappedFacility: json['MappedFacility'] ?? 0,
      visitedFacility: json['VisitedFacility'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'USERID': userId,
      'USERNAME': username,
      'Name': name,
      'MOBNO': mobNo,
      'EMAILID': emailId,
      'DesgId': desgId,
      'DesgName': desgName,
      'MappedFacility': mappedFacility,
      'VisitedFacility': visitedFacility,
    };
  }
}
