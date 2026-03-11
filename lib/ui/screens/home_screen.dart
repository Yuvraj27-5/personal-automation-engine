import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import '../../services/auto_trigger_service.dart';
import '../widgets/rule_card.dart';
import 'create_rule_screen.dart';
import 'logs_screen.dart';
import 'analytics_screen.dart';
import 'profile_screen.dart';
import 'sandbox_screen.dart';
import 'alerts_screen.dart';
import 'ai_suggest_screen.dart';
import 'ai_optimize_screen.dart';
import 'ai_insights_screen.dart';
import 'settings_screen.dart';

final userNameProvider = StateProvider<String>((ref) => 'Alex');

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _fabCtrl;
  late Animation<double> _fabScale;
  AutoTriggerService? _autoTrigger;

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fabScale = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut));
    Future.delayed(const Duration(milliseconds: 500), () { if (mounted) _fabCtrl.forward(); });

    // Start auto trigger engine after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoTrigger());
  }

  void _startAutoTrigger() {
    final engine = ref.read(engineProvider);
    _autoTrigger = AutoTriggerService(
      engine: engine,
      getRules: () => ref.read(rulesProvider),
      onLog: (log) => ref.read(logsProvider.notifier).addLog(log),
      getContext: () => context,
    );
    _autoTrigger!.start();
  }

  @override
  void dispose() {
    _autoTrigger?.stop();
    _fabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _RulesPage(),
      const LogsScreen(),
      const AnalyticsScreen(),
      const ProfileScreen(),
    ];
    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: _buildNav(),
      floatingActionButton: _currentIndex == 0
          ? ScaleTransition(scale: _fabScale,
              child: _GlowFAB(onPressed: () => Navigator.push(
                context, _slideRoute(const CreateRuleScreen()),
              ).then((_) => ref.read(rulesProvider.notifier).loadRules())))
          : null,
    );
  }

  Widget _buildNav() {
    final items = [
      (Icons.bolt_outlined, Icons.bolt, 'Rules'),
      (Icons.history_outlined, Icons.history, 'Logs'),
      (Icons.bar_chart_outlined, Icons.bar_chart, 'Stats'),
      (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
    ];
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, -5))],
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(items.length, (i) => _NavItem(
          icon: items[i].$1, activeIcon: items[i].$2, label: items[i].$3,
          selected: _currentIndex == i,
          onTap: () => setState(() => _currentIndex = i),
        )),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon; final String label;
  final bool selected; final VoidCallback onTap;
  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap, behavior: HitTestBehavior.opaque,
    child: AnimatedContainer(duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: selected ? BoxDecoration(borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: [AppTheme.primary.withOpacity(0.2), AppTheme.secondary.withOpacity(0.1)])) : null,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(selected ? activeIcon : icon, color: selected ? AppTheme.primary : AppTheme.textHint, size: 24),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(color: selected ? AppTheme.primary : AppTheme.textHint,
            fontSize: 11, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
      ])));
}

class _GlowFAB extends StatefulWidget {
  final VoidCallback onPressed;
  const _GlowFAB({required this.onPressed});
  @override State<_GlowFAB> createState() => _GlowFABState();
}
class _GlowFABState extends State<_GlowFAB> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _g;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _g = Tween<double>(begin: 0.4, end: 0.85).animate(_c);
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _g,
    builder: (_, __) => GestureDetector(onTap: widget.onPressed,
      child: Container(width: 60, height: 60,
        decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: const LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFF00B0D8)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(_g.value), blurRadius: 22, spreadRadius: 2)]),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 30))));
}

// ─────────────────────────────────────────────────────────────
// RULES PAGE
// ─────────────────────────────────────────────────────────────
class _RulesPage extends ConsumerStatefulWidget {
  const _RulesPage();
  @override ConsumerState<_RulesPage> createState() => _RulesPageState();
}

class _RulesPageState extends ConsumerState<_RulesPage>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  late AnimationController _headerCtrl;
  late Animation<double> _headerAnim;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _headerAnim = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic);
    _headerCtrl.forward();
  }

  @override
  void dispose() { _searchCtrl.dispose(); _headerCtrl.dispose(); super.dispose(); }

  Future<void> _runRule(rule) async {
    final engine = ref.read(engineProvider);

    // Wire display message action to show dialog on screen
    engine.onDisplayMessage = (msg, type) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: AppTheme.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primary.withOpacity(0.15),
                ),
                child: const Icon(Icons.message_outlined, color: AppTheme.primary, size: 30),
              ),
              const SizedBox(height: 16),
              const Text('Message', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(msg, textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15, height: 1.5)),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size(double.infinity, 46),
                ),
                child: const Text('OK'),
              ),
            ]),
          ),
        ),
      );
    };

    final result = await engine.runRule(rule);
    final log = await engine.logExecution(rule, result);

    // Save log to Firebase Realtime Database
    ref.read(logsProvider.notifier).addLog(log);

    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Text(result.success ? '✅' : '❌', style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(child: Text(result.message, style: const TextStyle(color: Colors.white))),
      ]),
      backgroundColor: result.success ? const Color(0xFF1A3A2A) : const Color(0xFF3A1A1A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(16),
    ));
  }

  Future<void> _deleteRule(String id) async {
    final confirm = await showDialog<bool>(context: context,
      builder: (ctx) => Dialog(backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.error.withOpacity(0.1)),
              child: const Icon(Icons.delete_outline, color: AppTheme.error, size: 32)),
          const SizedBox(height: 16),
          const Text('Delete Rule?', style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('This cannot be undone.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel'))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
              child: const Text('Delete'))),
          ]),
        ]))));
    if (confirm == true) ref.read(rulesProvider.notifier).deleteRule(id);
  }

  @override
  Widget build(BuildContext context) {
    final rules = ref.watch(displayedRulesProvider);
    final allRules = ref.watch(rulesProvider);
    final filter = ref.watch(filterEnabledProvider);
    final userName = ref.watch(userNameProvider);
    final themeColor = ref.watch(themeAccentProvider);
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    final unreadAlerts = 3;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [

          // ── HEADER ──────────────────────────────────────
          SliverToBoxAdapter(child: FadeTransition(opacity: _headerAnim,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              decoration: BoxDecoration(gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomCenter,
                colors: [AppTheme.primary.withOpacity(0.18), AppTheme.secondary.withOpacity(0.05), Colors.transparent])),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Top row: name + alert bell
                Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ShaderMask(
                      shaderCallback: (b) => const LinearGradient(
                          colors: [Color(0xFFE040FB), Color(0xFF7C4DFF), Color(0xFF40C4FF)]).createShader(b),
                      child: const Text('AutoEngine', style: TextStyle(
                          fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5))),
                    const SizedBox(height: 4),
                    Text('$greeting, $userName', style: const TextStyle(
                        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
                  ])),
                  // Alert bell with badge
                  GestureDetector(
                    onTap: () => Navigator.push(context, _slideRoute(const AlertsScreen())),
                    child: Stack(children: [
                      Container(width: 44, height: 44,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          color: themeColor.withOpacity(0.12),
                          border: Border.all(color: themeColor.withOpacity(0.3))),
                        child: Icon(Icons.notifications_outlined, color: themeColor, size: 22)),
                      if (unreadAlerts > 0) Positioned(top: 2, right: 2,
                        child: Container(width: 16, height: 16,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFEF5350),
                              border: Border.all(color: AppTheme.background, width: 1.5)),
                          child: Center(child: Text('$unreadAlerts',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800))))),
                    ]),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () => Navigator.push(context, _slideRoute(const SandboxScreen())),
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
                        color: AppTheme.secondary.withOpacity(0.12),
                        border: Border.all(color: AppTheme.secondary.withOpacity(0.3))),
                      child: Row(children: const [
                        Icon(Icons.science_outlined, color: AppTheme.secondary, size: 16),
                        SizedBox(width: 6),
                        Text('Sandbox', style: TextStyle(color: AppTheme.secondary, fontSize: 12, fontWeight: FontWeight.w600)),
                      ])),
                  ),
                ]),
                const SizedBox(height: 20),

                // ── STAT TILES (overflow fixed — no fixed height) ──
                IntrinsicHeight(child: Row(children: [
                  _StatTile(value: '${allRules.length}', label: 'Total Rules',
                      icon: Icons.bolt_rounded, colors: const [Color(0xFF7C4DFF), Color(0xFF9C6FFF)]),
                  const SizedBox(width: 12),
                  _StatTile(value: '${allRules.where((r) => r.isEnabled).length}', label: 'Active Now',
                      icon: Icons.check_circle_outline_rounded, colors: const [Color(0xFF00897B), Color(0xFF26A69A)]),
                  const SizedBox(width: 12),
                  _StatTile(value: '${allRules.where((r) => !r.isEnabled).length}', label: 'Paused',
                      icon: Icons.pause_circle_outline_rounded, colors: const [Color(0xFFE65100), Color(0xFFFF7043)]),
                ])),
                const SizedBox(height: 20),

                // ── AI FEATURES ──
                const Text('AI Features', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(children: [
                  _AITile(icon: Icons.auto_awesome_rounded, label: 'AI Suggest', subtitle: 'Smart rule ideas',
                    color: const Color(0xFF9D4EDD),
                    onTap: () => Navigator.push(context, _slideRoute(const AISuggestScreen()))),
                  const SizedBox(width: 10),
                  _AITile(icon: Icons.psychology_rounded, label: 'AI Optimize', subtitle: 'Improve rules',
                    color: const Color(0xFF0077B6),
                    onTap: () => Navigator.push(context, _slideRoute(const AIOptimizeScreen()))),
                  const SizedBox(width: 10),
                  _AITile(icon: Icons.analytics_outlined, label: 'AI Insights', subtitle: 'Usage patterns',
                    color: const Color(0xFFE040FB),
                    onTap: () => Navigator.push(context, _slideRoute(const AIInsightsScreen()))),
                ]),
              ]),
            ))),

          // ── TIP BANNER ───────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(colors: [
                  const Color(0xFF7C4DFF).withOpacity(0.15), const Color(0xFF00E5FF).withOpacity(0.08)]),
                border: Border.all(color: AppTheme.primary.withOpacity(0.2))),
              child: Row(children: [
                Container(width: 36, height: 36,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFFD600).withOpacity(0.15)),
                  child: const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFFFD600), size: 20)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Pro Tip', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  Text('Use Sandbox mode to safely test rules before enabling them.',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                ])),
              ])),
          )),

          // ── SEARCH + FILTER ──────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Column(children: [
              Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), color: AppTheme.cardBg,
                    border: Border.all(color: Colors.white.withOpacity(0.07))),
                child: TextField(controller: _searchCtrl,
                  onChanged: (v) => ref.read(searchQueryProvider.notifier).state = v,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(hintText: 'Search rules...',
                    prefixIcon: Icon(Icons.search_rounded, color: AppTheme.primary.withOpacity(0.7)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)))),
              const SizedBox(height: 12),
              SingleChildScrollView(scrollDirection: Axis.horizontal,
                child: Row(children: ['All', 'Enabled', 'Disabled'].map((f) => _FilterPill(
                  label: f, selected: filter == f,
                  onTap: () => ref.read(filterEnabledProvider.notifier).state = f)).toList())),
            ]))),

          // ── RULES HEADER ─────────────────────────────────
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: Row(children: [
              const Text('My Rules', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                child: Text('${rules.length}', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.bold))),
            ]))),

          // ── RULES LIST ────────────────────────────────────
          rules.isEmpty
              ? SliverFillRemaining(hasScrollBody: false, child: _EmptyState())
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  sliver: SliverList(delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _AnimatedRuleCard(index: i, rule: rules[i],
                      onTap: () => Navigator.push(ctx, _slideRoute(CreateRuleScreen(existingRule: rules[i])))
                          .then((_) => ref.read(rulesProvider.notifier).loadRules()),
                      onToggle: () => ref.read(rulesProvider.notifier).toggleRule(rules[i].id),
                      onDelete: () => _deleteRule(rules[i].id),
                      onRun: () => _runRule(rules[i])),
                    childCount: rules.length))),
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final String value, label; final IconData icon; final List<Color> colors;
  const _StatTile({required this.value, required this.label, required this.icon, required this.colors});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
      gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
      boxShadow: [BoxShadow(color: colors.first.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white.withOpacity(0.9), size: 20),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10),
          maxLines: 1, overflow: TextOverflow.ellipsis),
    ])));
}

class _AITile extends StatelessWidget {
  final IconData icon; final String label, subtitle; final Color color; final VoidCallback onTap;
  const _AITile({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(onTap: onTap,
    child: Container(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
        color: color.withOpacity(0.1), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.2)),
            child: Icon(icon, color: color, size: 20)),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9), textAlign: TextAlign.center),
      ]))));
}

class _FilterPill extends StatelessWidget {
  final String label; final bool selected; final VoidCallback onTap;
  const _FilterPill({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: AnimatedContainer(duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
        gradient: selected ? const LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFF00B0D8)]) : null,
        color: selected ? null : AppTheme.cardBg,
        border: Border.all(color: selected ? Colors.transparent : Colors.white.withOpacity(0.08))),
      child: Text(label, style: TextStyle(
          color: selected ? Colors.white : AppTheme.textSecondary,
          fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.normal))));
}

class _AnimatedRuleCard extends StatefulWidget {
  final int index; final dynamic rule;
  final VoidCallback onTap, onToggle, onDelete, onRun;
  const _AnimatedRuleCard({required this.index, required this.rule,
    required this.onTap, required this.onToggle, required this.onDelete, required this.onRun});
  @override State<_AnimatedRuleCard> createState() => _AnimatedRuleCardState();
}
class _AnimatedRuleCardState extends State<_AnimatedRuleCard> with SingleTickerProviderStateMixin {
  late AnimationController _c; late Animation<double> _op; late Animation<Offset> _sl;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _op = Tween<double>(begin: 0, end: 1).animate(_c);
    _sl = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.index * 80), () { if (mounted) _c.forward(); });
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(opacity: _op,
    child: SlideTransition(position: _sl,
      child: RuleCard(rule: widget.rule, onTap: widget.onTap,
          onToggle: widget.onToggle, onDelete: widget.onDelete, onRun: widget.onRun)));
}

class _EmptyState extends StatefulWidget {
  @override State<_EmptyState> createState() => _EmptyStateState();
}
class _EmptyStateState extends State<_EmptyState> with SingleTickerProviderStateMixin {
  late AnimationController _c; late Animation<double> _b;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _b = Tween<double>(begin: -8, end: 8).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: const EdgeInsets.only(bottom: 80),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      AnimatedBuilder(animation: _b,
        builder: (_, child) => Transform.translate(offset: Offset(0, _b.value), child: child),
        child: Container(width: 100, height: 100,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: LinearGradient(colors: [AppTheme.primary.withOpacity(0.3), AppTheme.secondary.withOpacity(0.2)])),
          child: const Center(child: Icon(Icons.bolt_rounded, color: Colors.white, size: 50)))),
      const SizedBox(height: 24),
      const Text('No rules yet!', style: TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Text('Tap + to create your first automation rule', textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7), fontSize: 14, height: 1.5)),
    ])));
}

PageRoute _slideRoute(Widget page) => PageRouteBuilder(
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, anim, __, child) => SlideTransition(
    position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)), child: child),
  transitionDuration: const Duration(milliseconds: 350));