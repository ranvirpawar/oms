class DenyRemarkModel {
  final int rid;
  final String denyRemark;

  DenyRemarkModel({
    required this.rid,
    required this.denyRemark,
  });

  factory DenyRemarkModel.fromJson(Map<String, dynamic> json) {
    return DenyRemarkModel(
      rid: json['RID'] as int,
      denyRemark: json['DenyRemark'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'RID': rid,
      'DenyRemark': denyRemark,
    };
  }
}
