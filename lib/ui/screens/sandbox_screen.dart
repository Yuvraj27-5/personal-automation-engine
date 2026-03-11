import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../engine/automation_engine.dart';
import '../../services/sound_service.dart';

class SandboxScreen extends ConsumerStatefulWidget {
  const SandboxScreen({super.key});
  @override ConsumerState<SandboxScreen> createState() => _SandboxScreenState();
}

class _SandboxScreenState extends ConsumerState<SandboxScreen>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  dynamic _selectedRule;
  bool _isRunning = false;
  ExecutionResult? _result;
  int _tabIndex = 0;
  final List<Map<String, dynamic>> _history = [];
  final List<String> _mockConditions = [];
  bool _soundEnabled = true;
  int _runCount = 0;
  double _successRate = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _runSandbox() async {
    if (_selectedRule == null) return;
    setState(() { _isRunning = true; _result = null; });
    final engine = ref.read(engineProvider);
    final result = await engine.runRule(_selectedRule!, sandbox: true);
    if (_soundEnabled) SoundService.playSound(result.success ? 'success' : 'error');
    final newEntry = {
      'rule': _selectedRule!.name,
      'success': result.success,
      'message': result.message,
      'time': DateTime.now(),
      'duration': result.durationMs,
    };
    setState(() {
      _isRunning = false;
      _result = result;
      _history.insert(0, newEntry);
      _runCount++;
      final successCount = _history.where((h) => h['success'] == true).length;
      _successRate = _history.isEmpty ? 0 : successCount / _history.length * 100;
    });
  }

  @override
  Widget build(BuildContext context) {
    final rules = ref.watch(rulesProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: _anim,
        child: Column(children: [
          _buildHeader(),
          _buildTabs(),
          Expanded(child: IndexedStack(
            index: _tabIndex,
            children: [
              _buildTestTab(rules),
              _buildHistoryTab(),
              _buildDebugTab(),
              _buildScenarioTab(),
            ],
          )),
        ]),
      ),
    );
  }

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.fromLTRB(20, 55, 20, 16),
    decoration: BoxDecoration(gradient: LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomCenter,
      colors: [AppTheme.secondary.withOpacity(0.18), Colors.transparent])),
    child: Row(children: [
      GestureDetector(onTap: () => Navigator.pop(context),
        child: Container(width: 40, height: 40,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.cardBg,
              border: Border.all(color: Colors.white.withOpacity(0.1))),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18))),
      const SizedBox(width: 14),
      Container(width: 40, height: 40,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
            color: AppTheme.secondary.withOpacity(0.2)),
        child: const Icon(Icons.science_outlined, color: AppTheme.secondary, size: 22)),
      const SizedBox(width: 10),
      const Text('Sandbox', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
      const Spacer(),
      // Sound toggle
      GestureDetector(
        onTap: () => setState(() => _soundEnabled = !_soundEnabled),
        child: Container(width: 36, height: 36,
          decoration: BoxDecoration(shape: BoxShape.circle,
            color: _soundEnabled ? AppTheme.secondary.withOpacity(0.2) : AppTheme.cardBg,
            border: Border.all(color: _soundEnabled ? AppTheme.secondary.withOpacity(0.4) : Colors.white.withOpacity(0.08))),
          child: Icon(_soundEnabled ? Icons.volume_up_outlined : Icons.volume_off_outlined,
              color: _soundEnabled ? AppTheme.secondary : Colors.white38, size: 18)),
      ),
    ]),
  );

  Widget _buildTabs() {
    final tabs = ['Test', 'History', 'Debug', 'Scenarios'];
    return Container(
      height: 44,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: AppTheme.cardBg,
          border: Border.all(color: Colors.white.withOpacity(0.06))),
      child: Row(children: List.generate(tabs.length, (i) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _tabIndex = i),
          child: AnimatedContainer(duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: _tabIndex == i ? const LinearGradient(
                  colors: [Color(0xFF00897B), Color(0xFF26A69A)]) : null),
            child: Center(child: Text(tabs[i], style: TextStyle(
                color: _tabIndex == i ? Colors.white : Colors.white38,
                fontSize: 13, fontWeight: _tabIndex == i ? FontWeight.w700 : FontWeight.normal)))),
        ),
      ))),
    );
  }

  Widget _buildTestTab(List rules) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      physics: const BouncingScrollPhysics(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Stats row
        Row(children: [
          _SbStat('$_runCount', 'Runs', Icons.play_circle_outline, AppTheme.secondary),
          const SizedBox(width: 10),
          _SbStat('${_successRate.toInt()}%', 'Success', Icons.check_circle_outline, const Color(0xFF66BB6A)),
          const SizedBox(width: 10),
          _SbStat('${_history.where((h) => h['success'] == false).length}', 'Failed', Icons.cancel_outlined, const Color(0xFFEF5350)),
        ]),
        const SizedBox(height: 16),

        // Sandbox info banner
        Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(colors: [AppTheme.secondary.withOpacity(0.15), AppTheme.secondary.withOpacity(0.05)]),
            border: Border.all(color: AppTheme.secondary.withOpacity(0.25))),
          child: Row(children: [
            const Icon(Icons.shield_outlined, color: AppTheme.secondary, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text('Sandbox mode: Rules run safely without side effects. No real actions are performed.',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, height: 1.5))),
          ])),
        const SizedBox(height: 16),

        // Rule selector
        const Text('Select Rule to Test', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 8),
        rules.isEmpty
          ? Container(padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: AppTheme.cardBg),
              child: Center(child: Text('No rules yet. Create a rule first.',
                  style: TextStyle(color: Colors.white.withOpacity(0.4)))))
          : Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: AppTheme.cardBg,
                  border: Border.all(color: Colors.white.withOpacity(0.07))),
              child: Column(children: rules.take(6).map((r) => GestureDetector(
                onTap: () => setState(() => _selectedRule = r),
                child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: _selectedRule?.id == r.id ? AppTheme.secondary.withOpacity(0.12) : Colors.transparent,
                    border: _selectedRule?.id == r.id ? Border.all(color: AppTheme.secondary.withOpacity(0.3)) : null),
                  child: Row(children: [
                    Icon(Icons.bolt_rounded, color: r.isEnabled ? AppTheme.secondary : Colors.white38, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(r.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                      Text('${r.trigger.displayName} → ${r.actions.length} action(s)',
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                    ])),
                    if (_selectedRule?.id == r.id)
                      const Icon(Icons.check_circle_rounded, color: AppTheme.secondary, size: 20),
                  ]),
                ),
              )).toList()),
            ),
        const SizedBox(height: 16),

        // Mock conditions
        const Text('Mock Conditions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 8),
        Container(padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: AppTheme.cardBg,
              border: Border.all(color: Colors.white.withOpacity(0.07))),
          child: Column(children: [
            ...[
              ('WiFi Connected', false),
              ('Battery > 50%', true),
              ('Time: 9:00 AM', true),
              ('Location: Home', false),
            ].map((c) {
              final val = ValueNotifier<bool>(c.$2);
              return Padding(padding: const EdgeInsets.only(bottom: 8),
                child: ValueListenableBuilder<bool>(
                  valueListenable: val,
                  builder: (_, v, __) => Row(children: [
                    Icon(Icons.check_box_outline_blank, color: Colors.white38, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(c.$1, style: const TextStyle(color: Colors.white70, fontSize: 13))),
                    Switch(value: v, onChanged: (nv) => val.value = nv,
                      activeColor: Colors.white, activeTrackColor: AppTheme.secondary,
                      inactiveTrackColor: Colors.white12, inactiveThumbColor: Colors.white38,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  ]),
                ));
            }),
          ]),
        ),
        const SizedBox(height: 16),

        // Run button
        GestureDetector(
          onTap: _selectedRule == null || _isRunning ? null : _runSandbox,
          child: AnimatedContainer(duration: const Duration(milliseconds: 200),
            width: double.infinity, height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: _selectedRule != null ? const LinearGradient(
                  colors: [Color(0xFF00897B), Color(0xFF26A69A)]) : null,
              color: _selectedRule == null ? AppTheme.cardBg : null,
            ),
            child: Center(child: _isRunning
              ? const SizedBox(width: 24, height: 24,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.play_arrow_rounded, color: _selectedRule != null ? Colors.white : Colors.white24, size: 24),
                  const SizedBox(width: 8),
                  Text('Run in Sandbox', style: TextStyle(
                      color: _selectedRule != null ? Colors.white : Colors.white24,
                      fontWeight: FontWeight.w700, fontSize: 16)),
                ])),
          ),
        ),

        // Result
        if (_result != null) ...[
          const SizedBox(height: 16),
          AnimatedContainer(duration: const Duration(milliseconds: 400),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(colors: [
                (_result!.success ? const Color(0xFF66BB6A) : const Color(0xFFEF5350)).withOpacity(0.15),
                (_result!.success ? const Color(0xFF66BB6A) : const Color(0xFFEF5350)).withOpacity(0.05),
              ]),
              border: Border.all(color: (_result!.success ? const Color(0xFF66BB6A) : const Color(0xFFEF5350)).withOpacity(0.3))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(_result!.success ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: _result!.success ? const Color(0xFF66BB6A) : const Color(0xFFEF5350), size: 22),
                const SizedBox(width: 10),
                Text(_result!.success ? 'Execution Successful' : 'Execution Failed',
                    style: TextStyle(color: _result!.success ? const Color(0xFF66BB6A) : const Color(0xFFEF5350),
                        fontWeight: FontWeight.w800, fontSize: 15)),
                const Spacer(),
                Text('${_result!.durationMs}ms', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
              ]),
              const SizedBox(height: 8),
              Text(_result!.message, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.4)),
              const SizedBox(height: 12),
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10), color: Colors.black.withOpacity(0.2)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Sandbox Log', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('> Rule: ${_selectedRule?.name ?? "Unknown"}', style: const TextStyle(color: Color(0xFF66BB6A), fontFamily: 'monospace', fontSize: 11)),
                  Text('> Status: ${_result!.success ? "PASS" : "FAIL"}', style: TextStyle(
                      color: _result!.success ? const Color(0xFF66BB6A) : const Color(0xFFEF5350), fontFamily: 'monospace', fontSize: 11)),
                  Text('> Duration: ${_result!.durationMs}ms', style: const TextStyle(color: Color(0xFF00B4D8), fontFamily: 'monospace', fontSize: 11)),
                  Text('> Mode: SANDBOX (no real actions)', style: TextStyle(color: Colors.white.withOpacity(0.4), fontFamily: 'monospace', fontSize: 11)),
                ])),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _buildHistoryTab() {
    if (_history.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.history, color: Colors.white24, size: 64),
      const SizedBox(height: 16),
      Text('No test history yet', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16)),
      const SizedBox(height: 8),
      Text('Run a rule in Sandbox to see results here', style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 13)),
    ]));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
      physics: const BouncingScrollPhysics(),
      itemCount: _history.length,
      itemBuilder: (_, i) {
        final h = _history[i];
        final success = h['success'] as bool;
        final color = success ? const Color(0xFF66BB6A) : const Color(0xFFEF5350);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: AppTheme.cardBg,
              border: Border.all(color: Colors.white.withOpacity(0.05))),
          child: Row(children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.15)),
              child: Icon(success ? Icons.check_rounded : Icons.close_rounded, color: color, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(h['rule'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              Text(h['message'] as String, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${h['duration']}ms', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
              Text(success ? 'PASS' : 'FAIL', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ]),
        );
      },
    );
  }

  Widget _buildDebugTab() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
    physics: const BouncingScrollPhysics(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('System State', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(height: 10),
      Container(padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: Colors.black.withOpacity(0.3),
            border: Border.all(color: Colors.white.withOpacity(0.07))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ...[
            ('platform', 'web (flutter)'),
            ('rules_loaded', ref.read(rulesProvider).length.toString()),
            ('logs_count', ref.read(logsProvider).length.toString()),
            ('sandbox_runs', _runCount.toString()),
            ('success_rate', '${_successRate.toStringAsFixed(1)}%'),
            ('timestamp', DateTime.now().toString().substring(0, 19)),
          ].map((kv) => Padding(padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              Text('${kv.$1}: ', style: const TextStyle(color: Color(0xFF00B4D8), fontSize: 12, fontFamily: 'monospace')),
              Text(kv.$2, style: const TextStyle(color: Color(0xFF66BB6A), fontSize: 12, fontFamily: 'monospace')),
            ]))),
        ])),
      const SizedBox(height: 16),
      const Text('Engine Diagnostics', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(height: 10),
      ...[
        ('Trigger Evaluator', true, 'Active'),
        ('Condition Checker', true, 'Ready'),
        ('Action Executor', true, 'Standby'),
        ('Conflict Detector', false, 'Disabled'),
        ('Log Writer', true, 'Active'),
      ].map((d) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: AppTheme.cardBg,
            border: Border.all(color: Colors.white.withOpacity(0.05))),
        child: Row(children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle,
              color: d.$2 ? const Color(0xFF66BB6A) : Colors.white24,
              boxShadow: d.$2 ? [BoxShadow(color: const Color(0xFF66BB6A).withOpacity(0.5), blurRadius: 6)] : null)),
          const SizedBox(width: 12),
          Expanded(child: Text(d.$1, style: const TextStyle(color: Colors.white70, fontSize: 13))),
          Text(d.$3, style: TextStyle(color: d.$2 ? const Color(0xFF66BB6A) : Colors.white38, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      )),
    ]),
  );

  Widget _buildScenarioTab() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 60),
    physics: const BouncingScrollPhysics(),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
          color: AppTheme.secondary.withOpacity(0.08),
          border: Border.all(color: AppTheme.secondary.withOpacity(0.2))),
        child: Row(children: [
          Icon(Icons.science_outlined, color: AppTheme.secondary, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text('Pre-built test scenarios to validate your rules in different conditions.',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12))),
        ])),
      const SizedBox(height: 16),
      ..._scenarios.map((s) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: AppTheme.cardBg,
            border: Border.all(color: Colors.white.withOpacity(0.05))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 40, height: 40,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: s.color.withOpacity(0.15)),
              child: Icon(s.icon, color: s.color, size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              Text(s.desc, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
            ])),
            GestureDetector(
              onTap: () { SoundService.playSound('notification'); _snack('Running scenario: ${s.title}'); },
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: s.color.withOpacity(0.15),
                    border: Border.all(color: s.color.withOpacity(0.3))),
                child: Text('Run', style: TextStyle(color: s.color, fontSize: 12, fontWeight: FontWeight.w700))),
            ),
          ]),
          const SizedBox(height: 10),
          Wrap(spacing: 6, children: s.conditions.map((c) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: Colors.white.withOpacity(0.06)),
            child: Text(c, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)))).toList()),
        ]),
      )),
    ]),
  );

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg),
      backgroundColor: const Color(0xFF1E2A3A), behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), margin: const EdgeInsets.all(16)));
  }

  final _scenarios = [
    _Scenario('Morning Routine', 'Simulates 9 AM weekday conditions', Icons.wb_sunny_outlined, const Color(0xFFFFAB40),
        ['Time: 9:00 AM', 'Day: Monday', 'WiFi: Connected', 'Battery: 85%']),
    _Scenario('Low Battery', 'Tests battery-triggered rules', Icons.battery_alert_outlined, const Color(0xFFEF5350),
        ['Battery: 15%', 'Charging: No', 'Time: 2:00 PM']),
    _Scenario('Night Mode', 'Simulates late-night phone usage', Icons.bedtime_outlined, const Color(0xFF7C4DFF),
        ['Time: 11:30 PM', 'Do Not Disturb: Off', 'Location: Home']),
    _Scenario('Work Hours', 'Simulates office environment', Icons.work_outline, const Color(0xFF00B4D8),
        ['WiFi: Office network', 'Time: 10:00 AM', 'Day: Weekday']),
    _Scenario('Weekend Relax', 'Tests weekend-specific rules', Icons.weekend_outlined, const Color(0xFF66BB6A),
        ['Day: Saturday', 'Time: 10:00 AM', 'Location: Home']),
  ];
}

class _Scenario {
  final String title, desc; final IconData icon; final Color color; final List<String> conditions;
  const _Scenario(this.title, this.desc, this.icon, this.color, this.conditions);
}

class _SbStat extends StatelessWidget {
  final String value, label; final IconData icon; final Color color;
  const _SbStat(this.value, this.label, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: AppTheme.cardBg,
        border: Border.all(color: Colors.white.withOpacity(0.05))),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 10)),
    ])));
}