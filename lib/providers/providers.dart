import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/rule_model.dart';
import '../data/models/log_model.dart';
import '../data/repositories/rule_repository.dart';
import '../engine/automation_engine.dart';
import '../services/analytics_service.dart';

// ── Repository ───────────────────────────────────────────────
final repositoryProvider = Provider<RuleRepository>((_) => RuleRepository());

// ── Engine ───────────────────────────────────────────────────
final engineProvider = Provider<AutomationEngine>((ref) {
  return AutomationEngine(ref.read(repositoryProvider));
});

// ── Rules ────────────────────────────────────────────────────
class RulesNotifier extends StateNotifier<List<RuleModel>> {
  final RuleRepository _repo;

  RulesNotifier(this._repo) : super([]) {
    loadRules();
  }

  void loadRules() => state = _repo.getAllRules();

  Future<void> addRule(RuleModel rule) async {
    await _repo.saveRule(rule);
    loadRules();
  }

  Future<void> updateRule(RuleModel rule) async {
    await _repo.updateRule(rule);
    loadRules();
  }

  Future<void> deleteRule(String id) async {
    await _repo.deleteRule(id);
    loadRules();
  }

  Future<void> toggleRule(String id) async {
    await _repo.toggleRule(id);
    loadRules();
  }

  Future<void> clearAll() async {
    await _repo.clearAll();
    loadRules();
  }
}

final rulesProvider =
    StateNotifierProvider<RulesNotifier, List<RuleModel>>((ref) {
  return RulesNotifier(ref.read(repositoryProvider));
});

// ── Logs ─────────────────────────────────────────────────────
class LogsNotifier extends StateNotifier<List<LogModel>> {
  final RuleRepository _repo;

  LogsNotifier(this._repo) : super([]) {
    loadLogs();
  }

  void loadLogs() => state = _repo.getAllLogs();

  Future<void> clearLogs() async {
    await _repo.clearLogs();
    loadLogs();
  }

  void addLog(LogModel log) {
    state = [log, ...state];
  }
}

final logsProvider =
    StateNotifierProvider<LogsNotifier, List<LogModel>>((ref) {
  return LogsNotifier(ref.read(repositoryProvider));
});

// ── Analytics ────────────────────────────────────────────────
final analyticsProvider = Provider((ref) {
  final logs = ref.watch(logsProvider);
  return {
    'overall': AnalyticsService.computeOverallStats(logs),
    'ruleStats': AnalyticsService.computeRuleStats(logs),
    'daily': AnalyticsService.computeDailyStats(logs, days: 7),
  };
});

// ── Search/Filter ────────────────────────────────────────────
final searchQueryProvider = StateProvider<String>((_) => '');

final filteredRulesProvider = Provider<List<RuleModel>>((ref) {
  final rules = ref.watch(rulesProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  if (query.isEmpty) return rules;
  return rules
      .where((r) =>
          r.name.toLowerCase().contains(query) ||
          r.description.toLowerCase().contains(query))
      .toList();
});

final filterEnabledProvider = StateProvider<String>((_) => 'All'); // All/Enabled/Disabled

final displayedRulesProvider = Provider<List<RuleModel>>((ref) {
  final rules = ref.watch(filteredRulesProvider);
  final filter = ref.watch(filterEnabledProvider);
  switch (filter) {
    case 'Enabled': return rules.where((r) => r.isEnabled).toList();
    case 'Disabled': return rules.where((r) => !r.isEnabled).toList();
    default: return rules;
  }
});
