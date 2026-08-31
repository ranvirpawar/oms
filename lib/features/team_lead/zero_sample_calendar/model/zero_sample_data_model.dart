class ZeroSampleResponse {
  final String status;
  final String message;
  final List<dynamic> output;

  ZeroSampleResponse({
    required this.status,
    required this.message,
    required this.output,
  });

  factory ZeroSampleResponse.fromJson(Map<String, dynamic> json) {
    return ZeroSampleResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      output: json['output'] ?? [],
    );
  }
}

class ZeroSampleData {
  final String visitDate;
  final int totalLabCode;
  final int totalFacilities;
  final int zeroSampleCount;
  final int remark;
  final int remarkByLBM;
  final int remarkByDC;

  ZeroSampleData({
    required this.visitDate,
    required this.totalLabCode,
    required this.totalFacilities,
    required this.zeroSampleCount,
    required this.remark,
    required this.remarkByLBM,
    required this.remarkByDC,
  });

  factory ZeroSampleData.fromJson(Map<String, dynamic> json) {
    return ZeroSampleData(
      visitDate: json['VISITDATE'] ?? '',
      totalLabCode: json['TotalLABCODE'] ?? 0,
      totalFacilities: json['TotalFacilities'] ?? 0,
      zeroSampleCount: json['ZERO_SAMPLECOUNT'] ?? 0,
      remark: json['REMARK'] ?? 0,
      remarkByLBM: json['RemarkByLBM'] ?? 0,
      remarkByDC: json['RemarkByDC'] ?? 0,
    );
  }
}

class RemarkData {
  final int remarkId;
  final String remarkHeader;
  final int totalFacilities;
  final int remark;
  final int remarkByLBM;
  final int remarkByDC;

  RemarkData({
    required this.remarkId,
    required this.remarkHeader,
    required this.totalFacilities,
    required this.remark,
    required this.remarkByLBM,
    required this.remarkByDC,
  });

  factory RemarkData.fromJson(Map<String, dynamic> json) {
    return RemarkData(
      remarkId: json['REMARKID'] ?? 0,
      remarkHeader: json['RemarkHeader'] ?? '',
      totalFacilities: json['TotalFacilities'] ?? 0,
      remark: json['REMARK'] ?? 0,
      remarkByLBM: json['RemarkByLBM'] ?? 0,
      remarkByDC: json['RemarkByDC'] ?? 0,
    );
  }
}