// sample_remark_model.dart
// Simple, null-safe Dart model for a remark record.



class SampleRemarkModel {
  final int remarkId;
  final String remark;


  SampleRemarkModel({
    required this.remarkId,
    required this.remark,

  });

  factory SampleRemarkModel.fromJson(Map<String, dynamic> json) {
    return SampleRemarkModel(
      remarkId: json['REMARKID'] ?? json['remarkId'] ?? 0,
      remark: json['REMARK'] ?? json['remarkName'] ?? '',

    );
  }

  Map<String, dynamic> toJson() {
    return {
      'REMARKID': remarkId,
      'REMARK': remark,

    };
  }
}