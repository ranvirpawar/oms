class NewFacilityType {
  final int fTypeId;
  final String fTypeName;

  NewFacilityType({
    required this.fTypeId,
    required this.fTypeName,
  });

  factory NewFacilityType.fromJson(Map<String, dynamic> json) {
    return NewFacilityType(
      fTypeId: int.tryParse(json['FTypeID'].toString()) ?? 0,
      fTypeName: json['FType']?.toString() ?? '',
    );
  }
}
