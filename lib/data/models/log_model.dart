import 'dart:convert';

class LogModel {
  final String id;
  final String ruleId;
  final String ruleName;
  final DateTime executedAt;
  final bool success;
  final String message;
  final int durationMs; // Performance monitoring
  final bool isSandbox;
  final List<String> actionsExecuted;

  const LogModel({
    required this.id,
    required this.ruleId,
    required this.ruleName,
    required this.executedAt,
    required this.success,
    required this.message,
    required this.durationMs,
    this.isSandbox = false,
    this.actionsExecuted = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'ruleId': ruleId,
        'ruleName': ruleName,
        'executedAt': executedAt.toIso8601String(),
        'success': success,
        'message': message,
        'durationMs': durationMs,
        'isSandbox': isSandbox,
        'actionsExecuted': actionsExecuted,
      };

  factory LogModel.fromJson(Map<String, dynamic> json) => LogModel(
        id: json['id'] as String,
        ruleId: json['ruleId'] as String,
        ruleName: json['ruleName'] as String,
        executedAt: DateTime.parse(json['executedAt'] as String),
        success: json['success'] as bool,
        message: json['message'] as String,
        durationMs: json['durationMs'] as int? ?? 0,
        isSandbox: json['isSandbox'] as bool? ?? false,
        actionsExecuted: List<String>.from(json['actionsExecuted'] as List? ?? []),
      );

  String toJsonString() => jsonEncode(toJson());
  factory LogModel.fromJsonString(String s) =>
      LogModel.fromJson(jsonDecode(s) as Map<String, dynamic>);
}
