import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../data/models/log_model.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});
  @override ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  String _filter = 'All';

  // Static alerts (system-level)
  final List<_AlertItem> _staticAlerts = [
    _AlertItem(title: 'Welcome to AutoEngine!', body: 'Start creating rules to automate your life.', time: 'Just now', type: 'info', read: false),
    _AlertItem(title: 'AI Suggestion', body: 'New rule idea: Battery Saver based on your patterns', time: '1h ago', type: 'ai', read: false),
    _AlertItem(title: 'AI Insight', body: 'Your peak activity is 9–11 AM. Consider adding more rules in this window.', time: '1d ago', type: 'ai', read: true),
    _AlertItem(title: 'System Alert', body: 'Firebase sync is active — your data is backed up in real-time.', time: '2d ago', type: 'info', read: true),
  ];

  bool _staticCleared = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  Color _typeColor(String type) {
    switch (type) {
      case 'success': return const Color(0xFF66BB6A);
      case 'error':   return const Color(0xFFEF5350);
      case 'warning': return const Color(0xFFFFAB40);
      case 'ai':      return const Color(0xFF9D4EDD);
      default:        return const Color(0xFF00B4D8);
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'success': return Icons.check_circle_outline_rounded;
      case 'error':   return Icons.error_outline_rounded;
      case 'warning': return Icons.warning_amber_outlined;
      case 'ai':      return Icons.auto_awesome_rounded;
      default:        return Icons.info_outline_rounded;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'success': return 'Success';
      case 'error':   return 'Error';
      case 'warning': return 'Warning';
      case 'ai':      return 'AI';
      default:        return 'Info';
    }
  }

  // Convert execution logs to alert items
  List<_AlertItem> _logsToAlerts(List<LogModel> logs) {
    return logs.take(20).map((log) => _AlertItem(
      title: log.success ? 'Rule Executed' : 'Rule Failed',
      body: '${log.ruleName} — ${log.message}',
      time: _timeAgo(log.executedAt),
      type: log.success ? 'success' : 'error',
      read: true,
    )).toList();
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 60, height: 60,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.error.withOpacity(0.1)),
              child: const Icon(Icons.delete_sweep_outlined, color: AppTheme.error, size: 30)),
            const SizedBox(height: 16),
            const Text('Clear All Alerts?',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('This will clear all alerts and execution logs.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ref.read(logsProvider.notifier).clearLogs();
                  setState(() => _staticCleared = true);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text('All alerts cleared!', style: TextStyle(color: Colors.white)),
                    backgroundColor: const Color(0xFF1A3A2A),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    margin: const EdgeInsets.all(16),
                  ));
                },
                child: const Text('Clear All'))),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final logs = ref.watch(logsProvider);
    final logAlerts = _logsToAlerts(logs);
    final staticItems = _staticCleared ? <_AlertItem>[] : _staticAlerts;
    final allAlerts = [...logAlerts, ...staticItems];

    List<_AlertItem> filtered;
    if (_filter == 'All') filtered = allAlerts;
    else if (_filter == 'Unread') filtered = allAlerts.where((a) => !a.read).toList();
    else filtered = allAlerts.where((a) => a.type == _filter.toLowerCase()).toList();

    final unreadCount = allAlerts.where((a) => !a.read).length;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: _anim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              decoration: BoxDecoration(gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomCenter,
                colors: [const Color(0xFF7C4DFF).withOpacity(0.15), Colors.transparent])),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  GestureDetector(onTap: () => Navigator.pop(context),
                    child: Container(width: 40, height: 40,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.cardBg,
                        border: Border.all(color: Colors.white.withOpacity(0.1))),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18))),
                  const SizedBox(width: 14),
                  const Text('Alerts',
                    style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                  const SizedBox(width: 10),
                  if (unreadCount > 0) Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: const Color(0xFF7C4DFF)),
                    child: Text('$unreadCount new', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700))),
                  const Spacer(),
                  // ── CLEAR ALL BUTTON ──
                  if (allAlerts.isNotEmpty) GestureDetector(
                    onTap: _clearAll,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: AppTheme.error.withOpacity(0.1),
                        border: Border.all(color: AppTheme.error.withOpacity(0.3))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.delete_sweep_outlined, color: AppTheme.error, size: 16),
                        const SizedBox(width: 6),
                        const Text('Clear All', style: TextStyle(color: AppTheme.error, fontSize: 12, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: ['All', 'Unread', 'Success', 'Error', 'AI'].map((f) =>
                    GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: _filter == f ? const LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFF00B0D8)]) : null,
                          color: _filter == f ? null : AppTheme.cardBg,
                          border: Border.all(color: _filter == f ? Colors.transparent : Colors.white.withOpacity(0.08))),
                        child: Text(f, style: TextStyle(
                          color: _filter == f ? Colors.white : Colors.white54,
                          fontSize: 12, fontWeight: _filter == f ? FontWeight.w700 : FontWeight.normal)),
                      ),
                    )).toList()),
                ),
              ]),
            )),

            filtered.isEmpty
              ? SliverFillRemaining(child: Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.notifications_none_rounded, color: Colors.white24, size: 64),
                    const SizedBox(height: 16),
                    Text('No alerts', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 18)),
                    const SizedBox(height: 8),
                    Text('Run a rule to see execution alerts here',
                      style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13)),
                  ])))
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 60),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final a = filtered[i];
                        final color = _typeColor(a.type);
                        return Dismissible(
                          key: Key('$i-${a.title}-${a.time}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: AppTheme.error.withOpacity(0.15)),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete_outline, color: AppTheme.error)),
                          onDismissed: (_) => setState(() => filtered.removeAt(i)),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              color: a.read ? AppTheme.cardBg : color.withOpacity(0.06),
                              border: Border.all(color: a.read ? Colors.white.withOpacity(0.05) : color.withOpacity(0.2))),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Container(width: 40, height: 40,
                                decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.15)),
                                child: Icon(_typeIcon(a.type), color: color, size: 20)),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Expanded(child: Text(a.title, style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: a.read ? FontWeight.w600 : FontWeight.w800,
                                    fontSize: 14))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: color.withOpacity(0.12)),
                                    child: Text(_typeLabel(a.type), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700))),
                                ]),
                                const SizedBox(height: 4),
                                Text(a.body, style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 12, height: 1.4)),
                                const SizedBox(height: 6),
                                Text(a.time, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
                              ])),
                              if (!a.read) Container(
                                width: 8, height: 8,
                                margin: const EdgeInsets.only(left: 8, top: 4),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle, color: color,
                                  boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)])),
                            ]),
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _AlertItem {
  final String title, body, time, type;
  final bool read;
  const _AlertItem({required this.title, required this.body,
    required this.time, required this.type, this.read = false});
}