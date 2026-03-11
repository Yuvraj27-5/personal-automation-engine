import 'dart:convert';
import 'trigger_model.dart';
import 'condition_model.dart';
import 'action_model.dart';

class RuleModel {
  final String id;
  final String name;
  final String description;
  final bool isEnabled;
  final TriggerModel trigger;
  final List<ConditionModel> conditions;
  final List<ActionModel> actions;
  final DateTime createdAt;
  final int priority; // 1=High 2=Medium 3=Low
  final bool hasConflict;
  final int executionCount;
  final DateTime? lastExecutedAt;

  const RuleModel({
    required this.id,
    required this.name,
    required this.description,
    required this.isEnabled,
    required this.trigger,
    required this.conditions,
    required this.actions,
    required this.createdAt,
    this.priority = 2,
    this.hasConflict = false,
    this.executionCount = 0,
    this.lastExecutedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'isEnabled': isEnabled,
        'trigger': trigger.toJson(),
        'conditions': conditions.map((c) => c.toJson()).toList(),
        'actions': actions.map((a) => a.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'priority': priority,
        'hasConflict': hasConflict,
        'executionCount': executionCount,
        'lastExecutedAt': lastExecutedAt?.toIso8601String(),
      };

  factory RuleModel.fromJson(Map<String, dynamic> json) => RuleModel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        isEnabled: json['isEnabled'] as bool? ?? true,
        trigger: TriggerModel.fromJson(
            Map<String, dynamic>.from(json['trigger'] as Map)),
        conditions: (json['conditions'] as List? ?? [])
            .map((c) =>
                ConditionModel.fromJson(Map<String, dynamic>.from(c as Map)))
            .toList(),
        actions: (json['actions'] as List? ?? [])
            .map((a) =>
                ActionModel.fromJson(Map<String, dynamic>.from(a as Map)))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        priority: json['priority'] as int? ?? 2,
        hasConflict: json['hasConflict'] as bool? ?? false,
        executionCount: json['executionCount'] as int? ?? 0,
        lastExecutedAt: json['lastExecutedAt'] != null
            ? DateTime.parse(json['lastExecutedAt'] as String)
            : null,
      );

  String toJsonString() => jsonEncode(toJson());
  factory RuleModel.fromJsonString(String s) =>
      RuleModel.fromJson(jsonDecode(s) as Map<String, dynamic>);

  RuleModel copyWith({
    String? id,
    String? name,
    String? description,
    bool? isEnabled,
    TriggerModel? trigger,
    List<ConditionModel>? conditions,
    List<ActionModel>? actions,
    DateTime? createdAt,
    int? priority,
    bool? hasConflict,
    int? executionCount,
    DateTime? lastExecutedAt,
  }) =>
      RuleModel(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        isEnabled: isEnabled ?? this.isEnabled,
        trigger: trigger ?? this.trigger,
        conditions: conditions ?? this.conditions,
        actions: actions ?? this.actions,
        createdAt: createdAt ?? this.createdAt,
        priority: priority ?? this.priority,
        hasConflict: hasConflict ?? this.hasConflict,
        executionCount: executionCount ?? this.executionCount,
        lastExecutedAt: lastExecutedAt ?? this.lastExecutedAt,
      );
}
