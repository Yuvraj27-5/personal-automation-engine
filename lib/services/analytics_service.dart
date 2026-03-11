import '../data/models/log_model.dart';

class RuleStats {
  final String ruleId;
  final String ruleName;
  final int totalExecutions;
  final int successCount;
  final int failureCount;
  final double avgDurationMs;
  final double successRate;
  final DateTime? lastExecuted;

  const RuleStats({
    required this.ruleId,
    required this.ruleName,
    required this.totalExecutions,
    required this.successCount,
    required this.failureCount,
    required this.avgDurationMs,
    required this.successRate,
    this.lastExecuted,
  });
}

class DailyStats {
  final DateTime date;
  final int executions;
  final int successes;

  const DailyStats({
    required this.date,
    required this.executions,
    required this.successes,
  });
}

class AnalyticsService {
  static Map<String, RuleStats> computeRuleStats(List<LogModel> logs) {
    final map = <String, List<LogModel>>{};
    for (final log in logs) {
      map.putIfAbsent(log.ruleId, () => []).add(log);
    }

    return map.map((id, ruleLogs) {
      final success = ruleLogs.where((l) => l.success).length;
      final total = ruleLogs.length;
      final avgMs = total > 0
          ? ruleLogs.map((l) => l.durationMs).reduce((a, b) => a + b) / total
          : 0.0;

      return MapEntry(
        id,
        RuleStats(
          ruleId: id,
          ruleName: ruleLogs.first.ruleName,
          totalExecutions: total,
          successCount: success,
          failureCount: total - success,
          avgDurationMs: avgMs,
          successRate: total > 0 ? (success / total) * 100 : 0,
          lastExecuted: ruleLogs.isNotEmpty
              ? ruleLogs
                  .reduce((a, b) =>
                      a.executedAt.isAfter(b.executedAt) ? a : b)
                  .executedAt
              : null,
        ),
      );
    });
  }

  static List<DailyStats> computeDailyStats(List<LogModel> logs,
      {int days = 7}) {
    final result = <DailyStats>[];
    final now = DateTime.now();

    for (int i = days - 1; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final dayLogs = logs.where((l) {
        final d = l.executedAt;
        return d.year == day.year &&
            d.month == day.month &&
            d.day == day.day &&
            !l.isSandbox;
      }).toList();

      result.add(DailyStats(
        date: day,
        executions: dayLogs.length,
        successes: dayLogs.where((l) => l.success).length,
      ));
    }

    return result;
  }

  static Map<String, int> computeOverallStats(List<LogModel> logs) {
    final real = logs.where((l) => !l.isSandbox).toList();
    return {
      'total': real.length,
      'success': real.where((l) => l.success).length,
      'failure': real.where((l) => !l.success).length,
      'sandbox': logs.where((l) => l.isSandbox).length,
      'avgDurationMs': real.isEmpty
          ? 0
          : (real.map((l) => l.durationMs).reduce((a, b) => a + b) ~/
              real.length),
    };
  }
}
