class ActionModel {
  final String type;
  final Map<String, dynamic> parameters;

  const ActionModel({
    required this.type,
    required this.parameters,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'parameters': parameters,
      };

  factory ActionModel.fromJson(Map<String, dynamic> json) => ActionModel(
        type: json['type'] as String,
        parameters: Map<String, dynamic>.from(json['parameters'] as Map),
      );

  ActionModel copyWith({String? type, Map<String, dynamic>? parameters}) =>
      ActionModel(
        type: type ?? this.type,
        parameters: parameters ?? this.parameters,
      );
}
