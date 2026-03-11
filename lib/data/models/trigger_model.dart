class TriggerModel {
  final String type;
  final Map<String, dynamic> parameters;

  const TriggerModel({
    required this.type,
    required this.parameters,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'parameters': parameters,
      };

  factory TriggerModel.fromJson(Map<String, dynamic> json) => TriggerModel(
        type: json['type'] as String,
        parameters: Map<String, dynamic>.from(json['parameters'] as Map),
      );

  TriggerModel copyWith({String? type, Map<String, dynamic>? parameters}) =>
      TriggerModel(
        type: type ?? this.type,
        parameters: parameters ?? this.parameters,
      );
}
