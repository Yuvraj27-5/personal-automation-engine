import '../local/rule_dao.dart';
import '../models/rule_model.dart';
import '../models/log_model.dart';

class RuleRepository {
  final _dao = RuleDao();

  List<RuleModel> getAllRules() => _dao.getAllRules();
  RuleModel? getRuleById(String id) => _dao.getRuleById(id);
  Future<void> saveRule(RuleModel rule) => _dao.saveRule(rule);
  Future<void> updateRule(RuleModel rule) => _dao.updateRule(rule);
  Future<void> deleteRule(String id) => _dao.deleteRule(id);
  Future<void> toggleRule(String id) => _dao.toggleRule(id);
  Future<void> incrementExecutionCount(String id) =>
      _dao.incrementExecutionCount(id);
  Future<void> clearAll() => _dao.clearAll();

  List<LogModel> getAllLogs() => _dao.getAllLogs();
  List<LogModel> getLogsForRule(String ruleId) =>
      _dao.getLogsForRule(ruleId);
  Future<void> saveLog(LogModel log) => _dao.saveLog(log);
  Future<void> clearLogs() => _dao.clearLogs();
}
