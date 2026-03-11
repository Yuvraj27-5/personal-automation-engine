import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AIOptimizeScreen extends StatefulWidget {
  const AIOptimizeScreen({super.key});
  @override State<AIOptimizeScreen> createState() => _AIOptimizeScreenState();
}

class _AIOptimizeScreenState extends State<AIOptimizeScreen>
    with TickerProviderStateMixin {
  late AnimationController _ctrl, _scanCtrl;
  late Animation<double> _anim, _scan;
  bool _isScanning = false;
  bool _scanned = false;

  final _tips = [
    _OptTip('Merge Time Triggers', 'You have 3 rules firing at 9 AM. Merge them to reduce overhead by ~30%.', Icons.merge_outlined, const Color(0xFF7C4DFF), '30% faster'),
    _OptTip('Remove Redundant Logs', '2 rules log the same event. One is redundant.', Icons.cleaning_services_outlined, const Color(0xFF00B4D8), 'Clean data'),
    _OptTip('Battery Optimisation', 'Run heavy rules only when charging for 40% less drain.', Icons.battery_charging_full_outlined, const Color(0xFF66BB6A), '40% less drain'),
    _OptTip('Condition Shortcut', 'Add a "WiFi connected" condition to 4 rules to skip unnecessary runs.', Icons.wifi_outlined, const Color(0xFFFFAB40), 'Skip 12 runs/day'),
    _OptTip('Conflict Detected', '2 rules conflict on Tuesday 9 PM. One will always override the other.', Icons.warning_amber_outlined, const Color(0xFFEF5350), '⚠ Fix needed'),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _scan = Tween<double>(begin: 0, end: 1).animate(_scanCtrl);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); _scanCtrl.dispose(); super.dispose(); }

  Future<void> _startScan() async {
    setState(() { _isScanning = true; _scanned = false; });
    await _scanCtrl.forward(from: 0);
    if (mounted) setState(() { _isScanning = false; _scanned = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: _anim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _header()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 60),
              sliver: SliverList(delegate: SliverChildListDelegate([

                // Scan card
                AnimatedBuilder(animation: _scan, builder: (_, __) => Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(colors: [
                      const Color(0xFF0077B6).withOpacity(0.2),
                      const Color(0xFF00B4D8).withOpacity(0.1)]),
                    border: Border.all(color: const Color(0xFF0077B6).withOpacity(0.3))),
                  child: Column(children: [
                    Stack(alignment: Alignment.center, children: [
                      if (_isScanning) ...[
                        Container(width: 100 + 60 * _scan.value, height: 100 + 60 * _scan.value,
                          decoration: BoxDecoration(shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF00B4D8).withOpacity(1 - _scan.value), width: 1.5))),
                        Container(width: 80 + 40 * _scan.value, height: 80 + 40 * _scan.value,
                          decoration: BoxDecoration(shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF7C4DFF).withOpacity(1 - _scan.value), width: 1))),
                      ],
                      Container(width: 80, height: 80,
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [
                            const Color(0xFF0077B6).withOpacity(0.3),
                            const Color(0xFF00B4D8).withOpacity(0.2)])),
                        child: Icon(_scanned ? Icons.check_rounded : Icons.psychology_rounded,
                            color: _scanned ? const Color(0xFF66BB6A) : const Color(0xFF00B4D8), size: 38)),
                    ]),
                    const SizedBox(height: 16),
                    Text(_isScanning ? 'Scanning your rules...' : _scanned ? 'Scan complete! Found ${_tips.length} optimisations' : 'AI Rule Analyser',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                    const SizedBox(height: 6),
                    Text(_isScanning ? 'Analysing patterns, conflicts and redundancies'
                        : _scanned ? 'Tap each suggestion to apply the fix'
                        : 'Run a deep scan to find performance issues and conflicts in your rules.',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.5),
                      textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    if (!_isScanning) GestureDetector(
                      onTap: _startScan,
                      child: Container(width: double.infinity, height: 50,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(colors: [Color(0xFF0077B6), Color(0xFF00B4D8)])),
                        child: Center(child: Text(_scanned ? 'Re-Scan' : 'Start AI Scan',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)))),
                    ),
                    if (_isScanning) LinearProgressIndicator(
                      value: _scan.value,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      color: const Color(0xFF00B4D8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ]),
                )),
                const SizedBox(height: 20),

                if (_scanned) ...[
                  const Text('Optimisation Report', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  ..._tips.asMap().entries.map((e) => _OptCard(tip: e.value, index: e.key)),
                ],
              ])),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() => Container(
    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
    decoration: BoxDecoration(gradient: LinearGradient(
      begin: Alignment.topLeft, end: Alignment.bottomCenter,
      colors: [const Color(0xFF0077B6).withOpacity(0.18), Colors.transparent])),
    child: Row(children: [
      GestureDetector(onTap: () => Navigator.pop(context),
        child: Container(width: 40, height: 40,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.cardBg,
              border: Border.all(color: Colors.white.withOpacity(0.1))),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18))),
      const SizedBox(width: 14),
      Container(width: 44, height: 44,
        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF0077B6).withOpacity(0.2)),
        child: const Icon(Icons.psychology_rounded, color: Color(0xFF0077B6), size: 22)),
      const SizedBox(width: 12),
      const Text('AI Optimizer', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
    ]),
  );
}

class _OptTip {
  final String title, desc, badge; final IconData icon; final Color color;
  const _OptTip(this.title, this.desc, this.icon, this.color, this.badge);
}

class _OptCard extends StatefulWidget {
  final _OptTip tip; final int index;
  const _OptCard({required this.tip, required this.index});
  @override State<_OptCard> createState() => _OptCardState();
}
class _OptCardState extends State<_OptCard> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  bool _applied = false;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    Future.delayed(Duration(milliseconds: widget.index * 120), () { if (mounted) _c.forward(); });
  }
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = widget.tip;
    return FadeTransition(opacity: _c, child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: AppTheme.cardBg,
        border: Border.all(color: _applied ? const Color(0xFF66BB6A).withOpacity(0.3) : Colors.white.withOpacity(0.05))),
      child: Row(children: [
        Container(width: 44, height: 44,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: t.color.withOpacity(0.15)),
          child: Icon(t.icon, color: t.color, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 3),
          Text(t.desc, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11, height: 1.4)),
          const SizedBox(height: 6),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), color: t.color.withOpacity(0.12)),
            child: Text(t.badge, style: TextStyle(color: t.color, fontSize: 10, fontWeight: FontWeight.w700))),
        ])),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => setState(() => _applied = true),
          child: AnimatedContainer(duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
              color: _applied ? const Color(0xFF66BB6A).withOpacity(0.15) : t.color.withOpacity(0.15),
              border: Border.all(color: _applied ? const Color(0xFF66BB6A).withOpacity(0.4) : t.color.withOpacity(0.3))),
            child: Text(_applied ? 'Applied' : 'Apply',
                style: TextStyle(color: _applied ? const Color(0xFF66BB6A) : t.color,
                    fontSize: 11, fontWeight: FontWeight.w700))),
        ),
      ]),
    ));
  }
}