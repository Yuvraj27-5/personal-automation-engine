import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/models/rule_model.dart';
import '../../data/models/trigger_model.dart';
import '../../data/models/action_model.dart';
import '../../data/models/condition_model.dart';
import '../../providers/providers.dart';

class AISuggestScreen extends ConsumerStatefulWidget {
  const AISuggestScreen({super.key});
  @override
  ConsumerState<AISuggestScreen> createState() => _AISuggestScreenState();
}

class _AISuggestScreenState extends ConsumerState<AISuggestScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  final Set<int> _added = {};
  String _filter = 'All';

  // Each suggestion maps directly to a real RuleModel
  final _suggestions = [
    _Suggestion(
      title: 'Morning Productivity',
      subtitle: 'Send focus reminder at 9 AM on weekdays',
      icon: Icons.wb_sunny_outlined,
      color: Color(0xFFFFAB40),
      triggerType: 'Time-based',
      priority: 'High',
      rule: _buildTimeRule('Morning Productivity',
        'Sends a focus reminder every morning at 9 AM',
        '09:00', 'Stay focused! Your morning productivity window starts now. 🚀', 1),
    ),
    _Suggestion(
      title: 'Battery Saver Alert',
      subtitle: 'Alert when battery drops below 20%',
      icon: Icons.battery_alert_outlined,
      color: Color(0xFFEF5350),
      triggerType: 'Battery trigger',
      priority: 'Medium',
      rule: _buildBatteryRule('Battery Saver Alert',
        'Alerts you when battery is critically low', 20),
    ),
    _Suggestion(
      title: 'Sleep Mode',
      subtitle: 'Reminder to sleep after 10 PM',
      icon: Icons.bedtime_outlined,
      color: Color(0xFF7C4DFF),
      triggerType: 'Time-based',
      priority: 'High',
      rule: _buildTimeRule('Sleep Mode',
        'Reminds you to sleep at 10 PM',
        '22:00', 'Time to sleep! Good rest = better productivity tomorrow. 🌙', 1),
    ),
    _Suggestion(
      title: 'Work Hours Log',
      subtitle: 'Log work session start every morning',
      icon: Icons.wifi_outlined,
      color: Color(0xFF00B4D8),
      triggerType: 'App Open',
      priority: 'Low',
      rule: _buildAppOpenRule('Work Hours Log',
        'Logs a work session every time the app opens'),
    ),
    _Suggestion(
      title: 'Daily Summary',
      subtitle: 'Get a daily automation report at 6 PM',
      icon: Icons.summarize_outlined,
      color: Color(0xFF66BB6A),
      triggerType: 'Time-based',
      priority: 'Medium',
      rule: _buildTimeRule('Daily Summary',
        'Sends your daily automation summary at 6 PM',
        '18:00', 'Daily Summary: Check your AutoEngine logs to see what ran today! 📊', 2),
    ),
    _Suggestion(
      title: 'Hydration Reminder',
      subtitle: 'Drink water every 2 hours',
      icon: Icons.water_drop_outlined,
      color: Color(0xFF00E5FF),
      triggerType: 'Interval',
      priority: 'Medium',
      rule: _buildIntervalRule('Hydration Reminder',
        'Reminds you to drink water every 2 hours', 120),
    ),
    _Suggestion(
      title: 'Focus Mode',
      subtitle: 'Start deep work reminder at 10 AM',
      icon: Icons.do_not_disturb_on_outlined,
      color: Color(0xFFAB47BC),
      triggerType: 'Time-based',
      priority: 'Medium',
      rule: _buildTimeRule('Focus Mode',
        'Starts your deep work focus session at 10 AM',
        '10:00', 'Focus Mode ON! Time for deep work. Put your phone away. 🎯', 2),
    ),
    _Suggestion(
      title: 'Hourly Stretch',
      subtitle: 'Remind yourself to stretch every hour',
      icon: Icons.self_improvement_outlined,
      color: Color(0xFF26C6DA),
      triggerType: 'Interval',
      priority: 'Low',
      rule: _buildIntervalRule('Hourly Stretch',
        'Reminds you to stretch every 60 minutes', 60),
    ),
  ];

  static RuleModel _buildTimeRule(String name, String desc, String time, String msg, int priority) {
    return RuleModel(
      id: const Uuid().v4(),
      name: name,
      description: desc,
      isEnabled: true,
      trigger: TriggerModel(type: AppConstants.triggerTime, parameters: {'time': time}),
      conditions: [],
      actions: [
        ActionModel(type: AppConstants.actionNotification, parameters: {'title': name, 'body': msg}),
        ActionModel(type: AppConstants.actionDisplayMessage, parameters: {'message': msg, 'type': 'snackbar'}),
      ],
      createdAt: DateTime.now(),
      priority: priority,
    );
  }

  static RuleModel _buildBatteryRule(String name, String desc, int threshold) {
    return RuleModel(
      id: const Uuid().v4(),
      name: name,
      description: desc,
      isEnabled: true,
      trigger: TriggerModel(type: AppConstants.triggerBattery, parameters: {'threshold': threshold}),
      conditions: [],
      actions: [
        ActionModel(type: AppConstants.actionNotification, parameters: {
          'title': '🔋 Low Battery!',
          'body': 'Battery below $threshold%. Please charge your device.',
        }),
        ActionModel(type: AppConstants.actionDisplayMessage, parameters: {
          'message': 'Battery below $threshold%! Connect charger now. 🔋',
          'type': 'snackbar',
        }),
      ],
      createdAt: DateTime.now(),
      priority: 2,
    );
  }

  static RuleModel _buildAppOpenRule(String name, String desc) {
    return RuleModel(
      id: const Uuid().v4(),
      name: name,
      description: desc,
      isEnabled: true,
      trigger: TriggerModel(type: AppConstants.triggerAppOpen, parameters: {}),
      conditions: [],
      actions: [
        ActionModel(type: AppConstants.actionLog, parameters: {'message': 'Work session started at ${DateTime.now()}'}),
      ],
      createdAt: DateTime.now(),
      priority: 3,
    );
  }

  static RuleModel _buildIntervalRule(String name, String desc, int minutes) {
    return RuleModel(
      id: const Uuid().v4(),
      name: name,
      description: desc,
      isEnabled: true,
      trigger: TriggerModel(type: AppConstants.triggerInterval, parameters: {'minutes': minutes}),
      conditions: [],
      actions: [
        ActionModel(type: AppConstants.actionNotification, parameters: {
          'title': name,
          'body': desc,
        }),
        ActionModel(type: AppConstants.actionDisplayMessage, parameters: {
          'message': '$name — $desc',
          'type': 'snackbar',
        }),
      ],
      createdAt: DateTime.now(),
      priority: 2,
    );
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  List<_Suggestion> get _filtered {
    if (_filter == 'All') return _suggestions;
    if (_filter == 'Time-based') return _suggestions.where((s) => s.triggerType == 'Time-based').toList();
    if (_filter == 'High Priority') return _suggestions.where((s) => s.priority == 'High').toList();
    return _suggestions;
  }

  Future<void> _addRule(int index) async {
    final suggestion = _suggestions[index];
    await ref.read(rulesProvider.notifier).addRule(suggestion.rule);
    setState(() => _added.add(index));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const Text('✅', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(child: Text('"${suggestion.title}" added to your rules!',
            style: const TextStyle(color: Colors.white))),
        ]),
        backgroundColor: const Color(0xFF1A3A2A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: _anim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _SuggestionCard(
                    suggestion: filtered[i],
                    isAdded: _added.contains(_suggestions.indexOf(filtered[i])),
                    index: i,
                    onAdd: () => _addRule(_suggestions.indexOf(filtered[i])),
                  ),
                  childCount: filtered.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomCenter,
          colors: [const Color(0xFF9D4EDD).withOpacity(0.2), Colors.transparent],
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(width: 40, height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.cardBg,
                border: Border.all(color: Colors.white.withOpacity(0.1))),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18)),
          ),
          const SizedBox(width: 14),
          Container(width: 44, height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: const Color(0xFF9D4EDD).withOpacity(0.2)),
            child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF9D4EDD), size: 22)),
          const SizedBox(width: 12),
          const Text('AI Rule Suggestions',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: const Color(0xFF9D4EDD).withOpacity(0.1),
            border: Border.all(color: const Color(0xFF9D4EDD).withOpacity(0.25))),
          child: Row(children: [
            const Icon(Icons.psychology_rounded, color: Color(0xFF9D4EDD), size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(
              'Tap + to instantly add any rule to your collection. No setup needed!',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.5))),
          ]),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: ['All', 'Time-based', 'High Priority'].map((f) =>
            GestureDetector(
              onTap: () => setState(() => _filter = f),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: _filter == f ? const LinearGradient(colors: [Color(0xFF9D4EDD), Color(0xFF7C4DFF)]) : null,
                  color: _filter == f ? null : AppTheme.cardBg,
                  border: Border.all(color: _filter == f ? Colors.transparent : Colors.white.withOpacity(0.1))),
                child: Text(f, style: TextStyle(
                  color: _filter == f ? Colors.white : Colors.white54,
                  fontSize: 12, fontWeight: _filter == f ? FontWeight.w700 : FontWeight.normal)),
              ),
            )).toList()),
        ),
      ]),
    );
  }
}

class _Suggestion {
  final String title, subtitle, triggerType, priority;
  final IconData icon;
  final Color color;
  final RuleModel rule;
  const _Suggestion({
    required this.title, required this.subtitle,
    required this.icon, required this.color,
    required this.triggerType, required this.priority,
    required this.rule,
  });
}

class _SuggestionCard extends StatefulWidget {
  final _Suggestion suggestion;
  final bool isAdded;
  final int index;
  final VoidCallback onAdd;
  const _SuggestionCard({required this.suggestion, required this.isAdded,
    required this.index, required this.onAdd});
  @override State<_SuggestionCard> createState() => _SuggestionCardState();
}

class _SuggestionCardState extends State<_SuggestionCard> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _op;
  late Animation<Offset> _sl;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _op = Tween<double>(begin: 0, end: 1).animate(_c);
    _sl = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.index * 80), () {
      if (mounted) _c.forward();
    });
  }

  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final s = widget.suggestion;
    final priorityColor = s.priority == 'High' ? const Color(0xFFEF5350)
      : s.priority == 'Medium' ? const Color(0xFFFFAB40) : const Color(0xFF66BB6A);

    return FadeTransition(opacity: _op, child: SlideTransition(position: _sl,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: AppTheme.cardBg,
          border: Border.all(color: widget.isAdded
            ? const Color(0xFF66BB6A).withOpacity(0.4) : Colors.white.withOpacity(0.06)),
        ),
        child: Row(children: [
          Container(width: 48, height: 48,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
              color: s.color.withOpacity(0.15)),
            child: Icon(s.icon, color: s.color, size: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 4),
            Text(s.subtitle, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
            const SizedBox(height: 8),
            Row(children: [
              _Tag(s.triggerType, s.color),
              const SizedBox(width: 6),
              _Tag(s.priority, priorityColor),
              if (widget.isAdded) ...[
                const SizedBox(width: 6),
                _Tag('Added ✓', const Color(0xFF66BB6A)),
              ],
            ]),
          ])),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: widget.isAdded ? null : widget.onAdd,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 44, height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: widget.isAdded ? null : LinearGradient(colors: [s.color, s.color.withOpacity(0.7)]),
                color: widget.isAdded ? const Color(0xFF66BB6A).withOpacity(0.2) : null,
                border: widget.isAdded ? Border.all(color: const Color(0xFF66BB6A)) : null,
                boxShadow: widget.isAdded ? null : [BoxShadow(color: s.color.withOpacity(0.3), blurRadius: 12)],
              ),
              child: Icon(widget.isAdded ? Icons.check_rounded : Icons.add_rounded,
                color: widget.isAdded ? const Color(0xFF66BB6A) : Colors.white, size: 22),
            ),
          ),
        ]),
      ),
    ));
  }
}

class _Tag extends StatelessWidget {
  final String label; final Color color;
  const _Tag(this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: color.withOpacity(0.12)),
    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)));
}