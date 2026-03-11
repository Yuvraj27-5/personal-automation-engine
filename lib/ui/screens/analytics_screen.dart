import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../providers/providers.dart';
import '../../services/analytics_service.dart';
import '../widgets/glass_card.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsProvider);
    final overall = analytics['overall'] as Map<String, int>;
    final ruleStats =
        analytics['ruleStats'] as Map<String, RuleStats>;
    final daily =
        analytics['daily'] as List<DailyStats>;

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall stats
            _buildOverallStats(overall),
            const SizedBox(height: 20),

            // Daily executions bar chart
            const Text('Executions (Last 7 Days)',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _DailyChart(data: daily),
            const SizedBox(height: 20),

            // Performance per rule
            const Text('Rule Performance',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (ruleStats.isEmpty)
              GlassCard(
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No executions yet',
                        style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                ),
              )
            else
              ...ruleStats.values.map((s) => _RuleStatCard(stats: s)),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStats(Map<String, int> overall) {
    final total = overall['total'] ?? 0;
    final success = overall['success'] ?? 0;
    final failure = overall['failure'] ?? 0;
    final sandbox = overall['sandbox'] ?? 0;
    final avgMs = overall['avgDurationMs'] ?? 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _StatTile(
              label: 'Total Runs',
              value: '$total',
              icon: Icons.play_circle,
              color: AppTheme.primary,
            )),
            const SizedBox(width: 10),
            Expanded(
                child: _StatTile(
              label: 'Success',
              value: '$success',
              icon: Icons.check_circle,
              color: AppTheme.success,
            )),
            const SizedBox(width: 10),
            Expanded(
                child: _StatTile(
              label: 'Failed',
              value: '$failure',
              icon: Icons.error_outline,
              color: AppTheme.error,
            )),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _StatTile(
              label: 'Sandbox Runs',
              value: '$sandbox',
              icon: Icons.science,
              color: AppTheme.secondary,
            )),
            const SizedBox(width: 10),
            Expanded(
                child: _StatTile(
              label: 'Avg Duration',
              value: AppDateUtils.formatDuration(avgMs),
              icon: Icons.timer_outlined,
              color: AppTheme.warning,
            )),
            const SizedBox(width: 10),
            Expanded(
                child: _StatTile(
              label: 'Success Rate',
              value: total > 0
                  ? '${((success / total) * 100).toStringAsFixed(0)}%'
                  : '-',
              icon: Icons.percent,
              color: AppTheme.primaryLight,
            )),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textHint, fontSize: 11)),
        ],
      ),
    );
  }
}

class _DailyChart extends StatelessWidget {
  final List<DailyStats> data;
  const _DailyChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: 180,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: (data.map((d) => d.executions).fold<int>(
                        0, (a, b) => a > b ? a : b) +
                    2)
                .toDouble(),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: AppTheme.cardBg,
                getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                  '${rod.toY.toInt()} runs',
                  const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 12),
                ),
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= data.length) {
                      return const SizedBox.shrink();
                    }
                    final d = data[i].date;
                    const days = [
                      'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'
                    ];
                    return Text(days[d.weekday - 1],
                        style: const TextStyle(
                            color: AppTheme.textHint, fontSize: 10));
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (v, _) => Text(
                    v.toInt().toString(),
                    style: const TextStyle(
                        color: AppTheme.textHint, fontSize: 10),
                  ),
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: AppTheme.divider,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: data.asMap().entries.map((e) {
              final i = e.key;
              final d = e.value;
              return BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: d.executions.toDouble(),
                    gradient: AppTheme.primaryGradient,
                    width: 16,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6)),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: (data
                                  .map((dd) => dd.executions)
                                  .fold<int>(0, (a, b) => a > b ? a : b) +
                              2)
                          .toDouble(),
                      color: AppTheme.surface,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _RuleStatCard extends StatelessWidget {
  final RuleStats stats;
  const _RuleStatCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(stats.ruleName,
                      style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ),
                Text(
                  '${stats.successRate.toStringAsFixed(0)}% success',
                  style: TextStyle(
                      color: stats.successRate > 70
                          ? AppTheme.success
                          : AppTheme.error,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Success rate bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: stats.successRate / 100,
                backgroundColor: AppTheme.error.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation(AppTheme.success),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _MiniStat('Runs', '${stats.totalExecutions}'),
                _MiniStat('Success', '${stats.successCount}'),
                _MiniStat('Failed', '${stats.failureCount}'),
                _MiniStat('Avg',
                    AppDateUtils.formatDuration(stats.avgDurationMs.toInt())),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textHint, fontSize: 10)),
        ],
      ),
    );
  }
}
