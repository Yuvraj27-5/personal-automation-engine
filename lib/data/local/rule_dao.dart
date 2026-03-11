import '../local/database_helper.dart';
import '../models/rule_model.dart';
import '../models/log_model.dart';

class RuleDao {
  // ── Rules ────────────────────────────────────────────────

  List<RuleModel> getAllRules() {
    final box = DatabaseHelper.rulesBox;
    final rules = box.values
        .map((s) => RuleModel.fromJsonString(s))
        .toList();
    rules.sort((a, b) => a.priority.compareTo(b.priority));
    return rules;
  }

  RuleModel? getRuleById(String id) {
    final val = DatabaseHelper.rulesBox.get(id);
    return val != null ? RuleModel.fromJsonString(val) : null;
  }

  Future<void> saveRule(RuleModel rule) async {
    await DatabaseHelper.rulesBox.put(rule.id, rule.toJsonString());
  }

  Future<void> deleteRule(String id) async {
    await DatabaseHelper.rulesBox.delete(id);
  }

  Future<void> updateRule(RuleModel rule) async {
    await DatabaseHelper.rulesBox.put(rule.id, rule.toJsonString());
  }

  Future<void> toggleRule(String id) async {
    final rule = getRuleById(id);
    if (rule != null) {
      await saveRule(rule.copyWith(isEnabled: !rule.isEnabled));
    }
  }

  Future<void> incrementExecutionCount(String id) async {
    final rule = getRuleById(id);
    if (rule != null) {
      await saveRule(rule.copyWith(
        executionCount: rule.executionCount + 1,
        lastExecutedAt: DateTime.now(),
      ));
    }
  }

  Future<void> clearAll() async {
    await DatabaseHelper.rulesBox.clear();
  }

  // ── Logs ─────────────────────────────────────────────────

  List<LogModel> getAllLogs() {
    final logs = DatabaseHelper.logsBox.values
        .map((s) => LogModel.fromJsonString(s))
        .toList();
    logs.sort((a, b) => b.executedAt.compareTo(a.executedAt));
    return logs;
  }

  List<LogModel> getLogsForRule(String ruleId) =>
      getAllLogs().where((l) => l.ruleId == ruleId).toList();

  Future<void> saveLog(LogModel log) async {
    await DatabaseHelper.logsBox.put(log.id, log.toJsonString());
    // Keep only last 500 logs
    final logs = getAllLogs();
    if (logs.length > 500) {
      final toDelete = logs.skip(500).map((l) => l.id).toList();
      for (final id in toDelete) {
        await DatabaseHelper.logsBox.delete(id);
      }
    }
  }

  Future<void> clearLogs() async {
    await DatabaseHelper.logsBox.clear();
  }
}
