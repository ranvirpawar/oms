class StateModel {
  final int stateId;
  final String stateName;

  StateModel({
    required this.stateId,
    required this.stateName,
  });

  factory StateModel.fromJson(Map<String, dynamic> json) {
    return StateModel(
      stateId: json['stateId'],
      stateName: json['stateName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stateId': stateId,
      'stateName': stateName,
    };
  }
}
