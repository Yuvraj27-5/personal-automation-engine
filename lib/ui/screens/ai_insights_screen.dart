import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({super.key});
  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen>
    with TickerProviderStateMixin {
  late AnimationController _pageCtrl, _barCtrl, _pulseCtrl;
  late Animation<double> _pageAnim, _barAnim, _pulseAnim;
  int _selectedDay = 0;
  final _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Hourly activity data (0-23 hours) per day
  final _activityData = [
    [0, 0, 0, 0, 0, 1, 3, 8, 12, 15, 14, 10, 9, 11, 13, 12, 10, 8, 7, 5, 4, 2, 1, 0], // Mon
    [0, 0, 0, 0, 0, 2, 4, 9, 11, 14, 16, 12, 8, 10, 14, 13, 11, 9, 6, 4, 3, 1, 0, 0], // Tue
    [0, 0, 0, 0, 1, 2, 5, 7, 13, 17, 15, 11, 10, 9, 12, 14, 12, 10, 7, 5, 3, 2, 1, 0], // Wed
    [0, 0, 0, 0, 0, 1, 3, 10, 14, 18, 16, 13, 11, 12, 15, 13, 11, 8, 6, 4, 2, 1, 0, 0], // Thu
    [0, 0, 0, 0, 0, 2, 4, 8, 12, 16, 14, 10, 9, 11, 13, 12, 9, 7, 5, 3, 2, 1, 0, 0], // Fri
    [0, 0, 0, 0, 0, 0, 1, 3, 5, 7, 9, 8, 7, 6, 5, 4, 5, 6, 7, 5, 4, 3, 1, 0],  // Sat
    [0, 0, 0, 0, 0, 0, 1, 2, 4, 6, 7, 8, 7, 6, 5, 4, 3, 4, 5, 6, 4, 2, 1, 0],  // Sun
  ];

  @override
  void initState() {
    super.initState();
    _pageCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _pageAnim = CurvedAnimation(parent: _pageCtrl, curve: Curves.easeOutCubic);

    _barCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _barAnim = CurvedAnimation(parent: _barCtrl, curve: Curves.easeOutCubic);

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(_pulseCtrl);

    _pageCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () { if (mounted) _barCtrl.forward(); });
  }

  @override
  void dispose() { _pageCtrl.dispose(); _barCtrl.dispose(); _pulseCtrl.dispose(); super.dispose(); }

  void _selectDay(int i) {
    setState(() => _selectedDay = i);
    _barCtrl.reset();
    _barCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final data = _activityData[_selectedDay];
    final maxVal = data.reduce(max).toDouble();
    final currentHour = DateTime.now().hour;
    final peakHour = data.indexOf(data.reduce(max));

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: _pageAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(children: [

                // ── DAY SELECTOR ──────────────────────────
                SizedBox(height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _days.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) => GestureDetector(
                      onTap: () => _selectDay(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: _selectedDay == i ? const LinearGradient(
                              colors: [Color(0xFFE040FB), Color(0xFF7C4DFF)]) : null,
                          color: _selectedDay == i ? null : AppTheme.cardBg,
                          border: Border.all(color: _selectedDay == i
                              ? Colors.transparent : Colors.white.withOpacity(0.08))),
                        child: Text(_days[i], style: TextStyle(
                            color: _selectedDay == i ? Colors.white : Colors.white54,
                            fontWeight: FontWeight.w600, fontSize: 13))),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── PEAK ACTIVITY CHART ───────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: AppTheme.cardBg,
                    border: Border.all(color: Colors.white.withOpacity(0.06))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      AnimatedBuilder(animation: _pulseAnim,
                        builder: (_, child) => Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFE040FB).withOpacity(_pulseAnim.value),
                            boxShadow: [BoxShadow(
                                color: const Color(0xFFE040FB).withOpacity(0.5),
                                blurRadius: 8 * _pulseAnim.value)],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Peak Activity', style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                      const Spacer(),
                      Text('Peak: ${_formatHour(peakHour)}',
                          style: TextStyle(color: const Color(0xFFE040FB), fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 6),
                    Text('Rule executions per hour — ${_days[_selectedDay]}',
                        style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12)),
                    const SizedBox(height: 20),

                    // Bar chart
                    AnimatedBuilder(
                      animation: _barAnim,
                      builder: (_, __) => SizedBox(
                        height: 140,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(24, (h) {
                            final val = data[h];
                            final barH = maxVal > 0 ? (val / maxVal) * 120 * _barAnim.value : 0.0;
                            final isCurrent = h == currentHour && _selectedDay == DateTime.now().weekday - 1;
                            final isPeak = h == peakHour;
                            return Expanded(child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 1.5),
                              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                                if (isPeak) Container(
                                  width: 4, height: 4,
                                  decoration: const BoxDecoration(
                                      shape: BoxShape.circle, color: Color(0xFFE040FB))),
                                const SizedBox(height: 2),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 50),
                                  height: barH.clamp(2, 120),
                                  decoration: BoxDecoration(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                      colors: isCurrent
                                          ? [const Color(0xFFE040FB), const Color(0xFF7C4DFF)]
                                          : isPeak
                                              ? [const Color(0xFFE040FB).withOpacity(0.9), const Color(0xFF9D4EDD).withOpacity(0.6)]
                                              : [const Color(0xFF7C4DFF).withOpacity(0.6), const Color(0xFF5390D9).withOpacity(0.3)],
                                    ),
                                  ),
                                ),
                              ]),
                            ));
                          }),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: ['12A', '6A', '12P', '6P', '11P'].map((t) =>
                        Text(t, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9))).toList()),
                  ]),
                ),
                const SizedBox(height: 16),

                // ── WEEKLY SUMMARY ────────────────────────
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
                      color: AppTheme.cardBg, border: Border.all(color: Colors.white.withOpacity(0.06))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Weekly Summary', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 14),
                    Row(children: [
                      _SummaryTile('Total Runs', '147', Icons.play_circle_outline, const Color(0xFF7C4DFF)),
                      _SummaryTile('Success Rate', '94%', Icons.check_circle_outline, const Color(0xFF66BB6A)),
                      _SummaryTile('Peak Hour', '10 AM', Icons.schedule, const Color(0xFFFFAB40)),
                      _SummaryTile('Top Rule', 'Gym', Icons.star_outline, const Color(0xFFE040FB)),
                    ]),
                  ]),
                ),
                const SizedBox(height: 16),

                // ── INSIGHTS LIST ─────────────────────────
                ..._insightItems.map((item) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(18),
                      color: AppTheme.cardBg, border: Border.all(color: Colors.white.withOpacity(0.05))),
                  child: Row(children: [
                    Container(width: 44, height: 44,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                          color: item.color.withOpacity(0.15)),
                      child: Icon(item.icon, color: item.color, size: 22)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 3),
                      Text(item.desc, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, height: 1.4)),
                    ])),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
                          color: item.color.withOpacity(0.12)),
                      child: Text(item.badge, style: TextStyle(color: item.color, fontSize: 11, fontWeight: FontWeight.w700))),
                  ]),
                )),

                const SizedBox(height: 40),
              ]),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
    decoration: BoxDecoration(gradient: LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomCenter,
      colors: [const Color(0xFFE040FB).withOpacity(0.15), Colors.transparent])),
    child: Row(children: [
      GestureDetector(onTap: () => Navigator.pop(context),
        child: Container(width: 40, height: 40,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.cardBg,
              border: Border.all(color: Colors.white.withOpacity(0.1))),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18))),
      const SizedBox(width: 14),
      Container(width: 44, height: 44,
        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFE040FB).withOpacity(0.2)),
        child: const Icon(Icons.analytics_outlined, color: Color(0xFFE040FB), size: 22)),
      const SizedBox(width: 12),
      const Text('AI Insights', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
    ]),
  );

  String _formatHour(int h) {
    if (h == 0) return '12 AM';
    if (h < 12) return '$h AM';
    if (h == 12) return '12 PM';
    return '${h - 12} PM';
  }

  final _insightItems = [
    _InsightItem('Peak Activity', 'Your rules run most between 9 AM - 11 AM on weekdays', Icons.schedule, const Color(0xFF7C4DFF), 'Morning'),
    _InsightItem('Top Rule Type', 'Time-based rules make up 60% of your automations', Icons.pie_chart_outline, const Color(0xFFE040FB), '60%'),
    _InsightItem('7-Day Streak', 'AutoEngine has been running for 7 days straight!', Icons.local_fire_department_outlined, const Color(0xFFFF6D00), '🔥'),
    _InsightItem('Efficiency Score', 'Your rules have a 94% success rate this week', Icons.speed_outlined, const Color(0xFF66BB6A), '94%'),
    _InsightItem('Smart Suggestion', 'Consider adding a weekend sleep schedule rule', Icons.auto_awesome_rounded, const Color(0xFF00B4D8), 'New'),
  ];
}

class _InsightItem {
  final String title, desc, badge; final IconData icon; final Color color;
  const _InsightItem(this.title, this.desc, this.icon, this.color, this.badge);
}

class _SummaryTile extends StatelessWidget {
  final String label, value; final IconData icon; final Color color;
  const _SummaryTile(this.label, this.value, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Icon(icon, color: color, size: 20),
    const SizedBox(height: 4),
    Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
    Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10), textAlign: TextAlign.center),
  ]));
}