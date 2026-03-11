import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/log_model.dart';
import '../../providers/providers.dart';
import '../widgets/glass_card.dart';

class LogsScreen extends ConsumerWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(logsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Execution Logs'),
        actions: [
          if (logs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear Logs',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppTheme.cardBg,
                    title: const Text('Clear All Logs',
                        style: TextStyle(color: AppTheme.textPrimary)),
                    content: const Text(
                        'Delete all execution logs?',
                        style:
                            TextStyle(color: AppTheme.textSecondary)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.error),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  ref.read(logsProvider.notifier).clearLogs();
                }
              },
            ),
        ],
      ),
      body: logs.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('📋', style: TextStyle(fontSize: 64)),
                  SizedBox(height: 16),
                  Text('No logs yet',
                      style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  Text('Run rules to see execution history',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 14)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              separatorBuilder: (_, i) {
                // Date separator
                if (i < logs.length - 1) {
                  final curr = logs[i].executedAt;
                  final next = logs[i + 1].executedAt;
                  if (curr.day != next.day) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(child: Divider(color: AppTheme.divider)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              AppDateUtils.formatDate(next),
                              style: const TextStyle(
                                  color: AppTheme.textHint, fontSize: 11),
                            ),
                          ),
                          Expanded(child: Divider(color: AppTheme.divider)),
                        ],
                      ),
                    );
                  }
                }
                return const SizedBox(height: 8);
              },
              itemBuilder: (ctx, i) => _LogItem(log: logs[i]),
            ),
    );
  }
}

class _LogItem extends StatelessWidget {
  final LogModel log;
  const _LogItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final isSuccess = log.success;
    final color = log.isSandbox
        ? AppTheme.secondary
        : isSuccess
            ? AppTheme.success
            : AppTheme.error;

    return GlassCard(
      padding: const EdgeInsets.all(0),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Color strip + icon
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(20)),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                log.isSandbox
                    ? Icons.science
                    : isSuccess
                        ? Icons.check_circle
                        : Icons.error_outline,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            log.ruleName,
                            style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                          ),
                        ),
                        if (log.isSandbox)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.secondary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('SANDBOX',
                                style: TextStyle(
                                    color: AppTheme.secondary,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      log.message,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    // Actions executed
                    if (log.actionsExecuted.isNotEmpty)
                      ...log.actionsExecuted.map((a) => Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                const Icon(Icons.arrow_right,
                                    color: AppTheme.textHint, size: 14),
                                Expanded(
                                  child: Text(a,
                                      style: const TextStyle(
                                          color: AppTheme.textHint,
                                          fontSize: 11),
                                      maxLines: 1,
                                      overflow:
                                          TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          )),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          AppDateUtils.formatDateTime(log.executedAt),
                          style: const TextStyle(
                              color: AppTheme.textHint, fontSize: 10),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '⚡ ${AppDateUtils.formatDuration(log.durationMs)}',
                            style: const TextStyle(
                                color: AppTheme.textHint,
                                fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
