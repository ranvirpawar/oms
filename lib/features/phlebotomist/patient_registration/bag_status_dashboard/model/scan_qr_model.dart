// models/bag_count_model.dart
class BagCountModel {
  final String status;
  final String message;
  final List<BagCountOutput>? output;

  BagCountModel({
    required this.status,
    required this.message,
    this.output,
  });

  factory BagCountModel.fromJson(Map<String, dynamic> json) {
    return BagCountModel(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      output: json['output'] != null
          ? (json['output'] as List)
          .map((e) => BagCountOutput.fromJson(e))
          .toList()
          : null,
    );
  }
}

class BagCountOutput {
  final int bagID;
  final int bagcapacity;
  final int tubecount;
  final int spaceVacnt;

  BagCountOutput({
    required this.bagID,
    required this.bagcapacity,
    required this.tubecount,
    required this.spaceVacnt,
  });

  factory BagCountOutput.fromJson(Map<String, dynamic> json) {
    return BagCountOutput(
      bagID: json['BagID'] ?? 0,
      bagcapacity: json['Bagcapacity'] ?? 0,
      tubecount: json['Tubecount'] ?? 0,
      spaceVacnt: json['SpaceVacnt'] ?? 0,
    );
  }
}