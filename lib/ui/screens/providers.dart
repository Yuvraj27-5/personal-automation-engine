import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/models/rule_model.dart';
import '../data/models/log_model.dart';
import '../services/firebase_service.dart';
import '../services/analytics_service.dart';

final _fb = FirebaseService();

// ── Auth ──────────────────────────────────────────────────────
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final userNameProvider = StateProvider<String>((ref) {
  return FirebaseAuth.instance.currentUser?.displayName ?? 'User';
});

// ── Rules ─────────────────────────────────────────────────────
class RulesNotifier extends StateNotifier<List<RuleModel>> {
  RulesNotifier() : super([]) {
    _listen();
  }

  void _listen() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { state = []; return; }
    _fb.rulesStream().listen((rules) => state = rules);
  }

  Future<void> addRule(RuleModel rule) => _fb.saveRule(rule);
  Future<void> updateRule(RuleModel rule) => _fb.saveRule(rule);
  Future<void> deleteRule(String id) => _fb.deleteRule(id);
  Future<void> toggleRule(String id) {
    final rule = state.firstWhere((r) => r.id == id);
    return _fb.toggleRule(id, rule.isEnabled);
  }
  Future<void> clearAll() => _fb.clearAllRules();
  void reload() => _listen();
}

final rulesProvider = StateNotifierProvider<RulesNotifier, List<RuleModel>>((ref) {
  ref.watch(authStateProvider);
  return RulesNotifier();
});

// ── Logs ──────────────────────────────────────────────────────
class LogsNotifier extends StateNotifier<List<LogModel>> {
  LogsNotifier() : super([]) {
    _listen();
  }

  void _listen() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { state = []; return; }
    _fb.logsStream().listen((logs) => state = logs);
  }

  Future<void> addLog(LogModel log) => _fb.saveLog(log);
  Future<void> clearLogs() => _fb.clearLogs();
  void reload() => _listen();
}

final logsProvider = StateNotifierProvider<LogsNotifier, List<LogModel>>((ref) {
  ref.watch(authStateProvider);
  return LogsNotifier();
});

// ── Analytics ─────────────────────────────────────────────────
final analyticsProvider = Provider((ref) {
  final logs = ref.watch(logsProvider);
  return {
    'overall': AnalyticsService.computeOverallStats(logs),
    'ruleStats': AnalyticsService.computeRuleStats(logs),
    'daily': AnalyticsService.computeDailyStats(logs, days: 7),
  };
});

// ── Search/Filter ─────────────────────────────────────────────
final searchQueryProvider = StateProvider<String>((_) => '');

final filteredRulesProvider = Provider<List<RuleModel>>((ref) {
  final rules = ref.watch(rulesProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  if (query.isEmpty) return rules;
  return rules.where((r) =>
    r.name.toLowerCase().contains(query) ||
    r.description.toLowerCase().contains(query)).toList();
});

final filterEnabledProvider = StateProvider<String>((_) => 'All');

final displayedRulesProvider = Provider<List<RuleModel>>((ref) {
  final rules = ref.watch(filteredRulesProvider);
  final filter = ref.watch(filterEnabledProvider);
  switch (filter) {
    case 'Enabled':  return rules.where((r) => r.isEnabled).toList();
    case 'Disabled': return rules.where((r) => !r.isEnabled).toList();
    default: return rules;
  }
});

// ── Engine ────────────────────────────────────────────────────
// Keep engine working with Firebase-backed logs
import '../engine/automation_engine.dart';
import '../data/repositories/rule_repository.dart';

final repositoryProvider = Provider<RuleRepository>((_) => RuleRepository());

final engineProvider = Provider<AutomationEngine>((ref) {
  final engine = AutomationEngine(ref.read(repositoryProvider));
  // Wire display message callback
  engine.onDisplayMessage = (msg, type) {};
  return engine;
});