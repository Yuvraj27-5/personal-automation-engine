class ConditionModel {
  final String type;
  final Map<String, dynamic> parameters;
  final String operator; // 'AND' | 'OR' (how this condition joins with the next)

  const ConditionModel({
    required this.type,
    required this.parameters,
    this.operator = 'AND',
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'parameters': parameters,
        'operator': operator,
      };

  factory ConditionModel.fromJson(Map<String, dynamic> json) => ConditionModel(
        type: json['type'] as String,
        parameters: Map<String, dynamic>.from(json['parameters'] as Map),
        operator: json['operator'] as String? ?? 'AND',
      );

  ConditionModel copyWith({
    String? type,
    Map<String, dynamic>? parameters,
    String? operator,
  }) =>
      ConditionModel(
        type: type ?? this.type,
        parameters: parameters ?? this.parameters,
        operator: operator ?? this.operator,
      );
}
