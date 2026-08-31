class IdentityProofModel {
  final int idTypeCode;
  final String idTypeName;
  final String idTypeDesc;
  final String activeFlag;
  final int creationUID;
  final String creationDateTime;
  final String? regularExp;

  IdentityProofModel({
    required this.idTypeCode,
    required this.idTypeName,
    required this.idTypeDesc,
    required this.activeFlag,
    required this.creationUID,
    required this.creationDateTime,
    this.regularExp,
  });

  factory IdentityProofModel.fromJson(Map<String, dynamic> json) {
    return IdentityProofModel(
      idTypeCode: json['IDTypeCode'],
      idTypeName: json['IDTypeName'],
      idTypeDesc: json['IDTypeDesc'],
      activeFlag: json['ActiveFlag'],
      creationUID: json['CreationUID'],
      creationDateTime: json['CreationDateTime'],
      regularExp: json['regularExp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'IDTypeCode': idTypeCode,
      'IDTypeName': idTypeName,
      'IDTypeDesc': idTypeDesc,
      'ActiveFlag': activeFlag,
      'CreationUID': creationUID,
      'CreationDateTime': creationDateTime,
      'regularExp': regularExp,
    };
  }
}
