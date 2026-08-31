class FacilityCenterType {
  final int centerTypeId;
  final String centerTypeName;

  FacilityCenterType({
    required this.centerTypeId,
    required this.centerTypeName,
  });

  factory FacilityCenterType.fromJson(Map<String, dynamic> json) {
    return FacilityCenterType(
      centerTypeId: int.parse(json['CenterTypeID'].toString()),
      centerTypeName: json['CenterTypName'] as String,
    );
  }
}
