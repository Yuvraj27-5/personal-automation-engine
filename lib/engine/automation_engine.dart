import 'package:uuid/uuid.dart';
import '../data/models/rule_model.dart';
import '../data/models/log_model.dart';
import '../data/models/action_model.dart';
import '../data/repositories/rule_repository.dart';
import '../core/constants/app_constants.dart';
import 'triggers/base_trigger.dart';
import 'triggers/triggers.dart';
import 'conditions/condition_evaluator.dart';
import 'actions/base_action.dart';
import 'actions/actions.dart';

class ExecutionResult {
  final bool triggered;
  final bool conditionsPassed;
  final bool success;
  final List<String> actionResults;
  final String message;
  final int durationMs;

  const ExecutionResult({
    required this.triggered,
    required this.conditionsPassed,
    required this.success,
    required this.actionResults,
    required this.message,
    required this.durationMs,
  });
}

class AutomationEngine {
  final RuleRepository _repository;
  final _uuid = const Uuid();
  Function(String message, String type)? onDisplayMessage;

  AutomationEngine(this._repository);

  // ── Public API ───────────────────────────────────────────

  /// Run all enabled rules for a given trigger type
  Future<List<LogModel>> runTrigger(String triggerType,
      {bool sandbox = false}) async {
    final rules = _repository
        .getAllRules()
        .where((r) => r.isEnabled && r.trigger.type == triggerType)
        .toList();

    // Sort by priority (1=High first)
    rules.sort((a, b) => a.priority.compareTo(b.priority));

    final logs = <LogModel>[];
    for (final rule in rules) {
      final log = await _executeRule(rule, sandbox: sandbox);
      if (log != null) logs.add(log);
    }
    return logs;
  }

  /// Run a single specific rule
  Future<ExecutionResult> runRule(RuleModel rule,
      {bool sandbox = false}) async {
    final stopwatch = Stopwatch()..start();
    final actionResults = <String>[];

    try {
      // 1. Check trigger
      final trigger = _buildTrigger(rule.trigger.type, rule);
      final shouldFire = await trigger.shouldFire();
      if (!shouldFire) {
        stopwatch.stop();
        return ExecutionResult(
          triggered: false,
          conditionsPassed: false,
          success: false,
          actionResults: [],
          message: 'Trigger did not fire',
          durationMs: stopwatch.elapsedMilliseconds,
        );
      }

      // 2. Evaluate conditions
      final evaluator = ConditionEvaluator();
      final conditionsPassed =
          await evaluator.evaluate(rule.conditions);
      if (!conditionsPassed) {
        stopwatch.stop();
        return ExecutionResult(
          triggered: true,
          conditionsPassed: false,
          success: false,
          actionResults: [],
          message: 'Conditions not met',
          durationMs: stopwatch.elapsedMilliseconds,
        );
      }

      // 3. Execute actions
      if (!sandbox) {
        for (final actionModel in rule.actions) {
          final action = _buildAction(actionModel);
          final result = await action.execute();
          actionResults.add(result);
        }
        await _repository.incrementExecutionCount(rule.id);
      } else {
        // Sandbox: simulate without real execution
        for (final actionModel in rule.actions) {
          actionResults.add('[SANDBOX] Would execute: ${_buildAction(actionModel).summary}');
        }
      }

      stopwatch.stop();
      return ExecutionResult(
        triggered: true,
        conditionsPassed: true,
        success: true,
        actionResults: actionResults,
        message: sandbox ? 'Sandbox run complete' : 'Rule executed successfully',
        durationMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      return ExecutionResult(
        triggered: true,
        conditionsPassed: true,
        success: false,
        actionResults: actionResults,
        message: 'Error: $e',
        durationMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  /// Log the result of running a rule
  Future<LogModel> logExecution(
    RuleModel rule,
    ExecutionResult result, {
    bool sandbox = false,
  }) async {
    final log = LogModel(
      id: _uuid.v4(),
      ruleId: rule.id,
      ruleName: rule.name,
      executedAt: DateTime.now(),
      success: result.success,
      message: result.message,
      durationMs: result.durationMs,
      isSandbox: sandbox,
      actionsExecuted: result.actionResults,
    );
    if (!sandbox) await _repository.saveLog(log);
    return log;
  }

  // ── Private Helpers ──────────────────────────────────────

  Future<LogModel?> _executeRule(RuleModel rule,
      {bool sandbox = false}) async {
    final result = await runRule(rule, sandbox: sandbox);
    if (result.triggered) {
      return logExecution(rule, result, sandbox: sandbox);
    }
    return null;
  }

  BaseTrigger _buildTrigger(String type, RuleModel rule) {
    switch (type) {
      case AppConstants.triggerTime:
        return TimeTrigger(rule.trigger);
      case AppConstants.triggerAppOpen:
        return AppOpenTrigger(rule.trigger);
      case AppConstants.triggerManual:
        return ManualTrigger(rule.trigger);
      case AppConstants.triggerBattery:
        return BatteryTrigger(rule.trigger);
      case AppConstants.triggerConnectivity:
        return ConnectivityTrigger(rule.trigger);
      case AppConstants.triggerInterval:
        return IntervalTrigger(rule.trigger);
      default:
        throw Exception('Unknown trigger type: $type');
    }
  }

  BaseAction _buildAction(ActionModel model) {
    switch (model.type) {
      case AppConstants.actionNotification:
        return NotificationAction(model);
      case AppConstants.actionLog:
        return LogAction(model);
      case AppConstants.actionDisplayMessage:
        return DisplayMessageAction(model, onDisplay: onDisplayMessage);
      case AppConstants.actionSound:
        return SoundAction(model);
      case AppConstants.actionClipboard:
        return ClipboardAction(model);
      case AppConstants.actionWebhook:
        return WebhookAction(model);
      default:
        throw Exception('Unknown action type: ${model.type}');
    }
  }
}
