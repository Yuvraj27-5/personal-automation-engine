import 'dart:math';
import 'package:flutter/material.dart';
import '../../main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Controllers
  late AnimationController _bgCtrl;      // ambient bg pulse
  late AnimationController _gridCtrl;    // hex grid fade in
  late AnimationController _ripple1, _ripple2, _ripple3;
  late AnimationController _orbitCtrl;   // orbital dots
  late AnimationController _logoCtrl;    // logo scale in
  late AnimationController _textCtrl;    // title + subtitle
  late AnimationController _pillCtrl;    // pills + button
  late AnimationController _pulseCtrl;   // glow pulse

  @override
  void initState() {
    super.initState();

    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
    _gridCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _orbitCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);

    _ripple1 = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _ripple2 = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _ripple3 = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _pillCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

    // Stagger sequence
    _gridCtrl.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _logoCtrl.forward();
      _ripple1.repeat();
    });
    Future.delayed(const Duration(milliseconds: 700), () { if (mounted) _ripple2.repeat(); });
    Future.delayed(const Duration(milliseconds: 1000), () { if (mounted) _ripple3.repeat(); });
    Future.delayed(const Duration(milliseconds: 1000), () { if (mounted) _textCtrl.forward(); });
    Future.delayed(const Duration(milliseconds: 1400), () { if (mounted) _pillCtrl.forward(); });
  }

  @override
  void dispose() {
    _bgCtrl.dispose(); _gridCtrl.dispose(); _orbitCtrl.dispose(); _pulseCtrl.dispose();
    _ripple1.dispose(); _ripple2.dispose(); _ripple3.dispose();
    _logoCtrl.dispose(); _textCtrl.dispose(); _pillCtrl.dispose();
    super.dispose();
  }

  void _navigate() => Navigator.pushReplacement(context, PageRouteBuilder(
    pageBuilder: (_, __, ___) => const AuthGate(),
    transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
    transitionDuration: const Duration(milliseconds: 600),
  ));

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_bgCtrl, _gridCtrl, _orbitCtrl, _pulseCtrl,
          _logoCtrl, _textCtrl, _pillCtrl, _ripple1, _ripple2, _ripple3]),
        builder: (context, _) {
          final bg = _bgCtrl.value;

          return Container(
            width: double.infinity, height: double.infinity,
            // Deep animated gradient background
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(bg * 0.4 - 0.2, -0.4 + bg * 0.2),
                radius: 1.8,
                colors: [
                  Color.lerp(const Color(0xFF120030), const Color(0xFF200050), bg)!,
                  Color.lerp(const Color(0xFF020820), const Color(0xFF051030), bg)!,
                  const Color(0xFF010510),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
            child: Stack(children: [
              // ── HEX GRID BACKGROUND ─────────────────────
              Opacity(
                opacity: (_gridCtrl.value * 0.25).clamp(0, 1),
                child: CustomPaint(
                  size: size,
                  painter: _HexGridPainter(
                    color: const Color(0xFF7C4DFF),
                    animValue: _bgCtrl.value,
                  ),
                ),
              ),

              // ── AMBIENT BLOBS ────────────────────────────
              _Blob(0.1, 0.08, size.width * 0.8,  const Color(0xFF7C4DFF), 0,       bg),
              _Blob(0.85, 0.65, size.width * 0.7, const Color(0xFF00B4D8), pi,      bg),
              _Blob(0.5,  0.9,  size.width * 0.6, const Color(0xFFE040FB), pi / 2,  bg),

              // ── STARS ────────────────────────────────────
              ..._buildStars(size, bg),

              // ── FLOATING PARTICLES ───────────────────────
              ..._buildParticles(size, bg),

              // ── CONTENT ──────────────────────────────────
              SafeArea(child: Column(children: [
                const Spacer(flex: 2),

                // Logo section
                SizedBox(width: 340, height: 340,
                  child: Stack(alignment: Alignment.center, children: [

                    // Outer sweeping arc
                    Transform.rotate(
                      angle: _orbitCtrl.value * 2 * pi,
                      child: CustomPaint(
                        size: const Size(300, 300),
                        painter: _ArcPainter(
                          color: const Color(0xFF7C4DFF),
                          sweepAngle: pi * 0.6,
                          strokeWidth: 1.2,
                        ),
                      ),
                    ),
                    // Counter arc
                    Transform.rotate(
                      angle: -_orbitCtrl.value * 2 * pi * 1.4,
                      child: CustomPaint(
                        size: const Size(245, 245),
                        painter: _ArcPainter(
                          color: const Color(0xFF00E5FF),
                          sweepAngle: pi * 0.4,
                          strokeWidth: 1.0,
                        ),
                      ),
                    ),
                    // Inner dashed ring
                    Transform.rotate(
                      angle: _orbitCtrl.value * 2 * pi * 0.7,
                      child: CustomPaint(
                        size: const Size(190, 190),
                        painter: _DashedRingPainter(const Color(0xFFE040FB).withOpacity(0.4)),
                      ),
                    ),

                    // Ripples
                    _Ripple(_ripple3, 150, const Color(0xFF7C4DFF), 1.2),
                    _Ripple(_ripple2, 118, const Color(0xFF5B8EFF), 1.6),
                    _Ripple(_ripple1, 88,  const Color(0xFF00E5FF), 2.0),

                    // Pulsing glow
                    Container(
                      width: 140 * (0.85 + 0.15 * _pulseCtrl.value),
                      height: 140 * (0.85 + 0.15 * _pulseCtrl.value),
                      decoration: BoxDecoration(shape: BoxShape.circle,
                        gradient: RadialGradient(colors: [
                          const Color(0xFF7C4DFF).withOpacity(0.35 * _pulseCtrl.value),
                          Colors.transparent,
                        ])),
                    ),

                    // Orbiting dots (6 dots, staggered)
                    ..._buildOrbitDots(),

                    // Main logo circle
                    Transform.scale(
                      scale: CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut).value,
                      child: Container(
                        width: 110, height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFBB44FF), Color(0xFF5390D9), Color(0xFF00D4FF)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(color: const Color(0xFF7C4DFF).withOpacity(0.9 * _pulseCtrl.value), blurRadius: 55, spreadRadius: 10),
                            BoxShadow(color: const Color(0xFF00D4FF).withOpacity(0.4), blurRadius: 30),
                          ],
                        ),
                        child: Center(
                          child: ShaderMask(
                            shaderCallback: (b) => const LinearGradient(
                              colors: [Colors.white, Color(0xFFE8D5FF)],
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                            ).createShader(b),
                            child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 62),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 28),

                // App name
                Transform.translate(
                  offset: Offset(0, (1 - CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic).value) * 40),
                  child: Opacity(
                    opacity: _textCtrl.value,
                    child: Column(children: [
                      // Gradient title
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [Color(0xFFE040FB), Color(0xFF9B59FF), Color(0xFF40C4FF)],
                          begin: Alignment.centerLeft, end: Alignment.centerRight,
                        ).createShader(b),
                        child: const Text('AutoEngine',
                          style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900,
                            color: Colors.white, letterSpacing: -2.0)),
                      ),
                      const SizedBox(height: 8),
                      // Animated typewriter-style subtitle
                      RichText(text: TextSpan(
                        style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.5), letterSpacing: 0.3),
                        children: const [
                          TextSpan(text: 'Smart rules. '),
                          TextSpan(text: 'Effortless', style: TextStyle(color: Color(0xFF9B59FF), fontWeight: FontWeight.w600)),
                          TextSpan(text: ' life.'),
                        ],
                      )),
                    ]),
                  ),
                ),

                const Spacer(flex: 2),

                // Pills + Get Started
                Opacity(
                  opacity: CurvedAnimation(parent: _pillCtrl, curve: Curves.easeOut).value,
                  child: Column(children: [
                    // Feature pills
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _FeaturePill(Icons.track_changes_rounded, '6 Triggers', const Color(0xFF7C4DFF)),
                      const SizedBox(width: 10),
                      _FeaturePill(Icons.settings_rounded,       '6 Actions',  const Color(0xFF00B4D8)),
                      const SizedBox(width: 10),
                      _FeaturePill(Icons.psychology_rounded,     'Smart AI',   const Color(0xFFE040FB)),
                    ]),
                    const SizedBox(height: 28),

                    // Get Started button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: _GetStartedBtn(onTap: _navigate),
                    ),

                    const SizedBox(height: 16),
                    Text('Built for curious builders',
                      style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.28), letterSpacing: 0.5)),
                    const SizedBox(height: 52),
                  ]),
                ),
              ])),
            ]),
          );
        },
      ),
    );
  }

  List<Widget> _buildOrbitDots() {
    final colors = [
      const Color(0xFF7C4DFF), const Color(0xFF00E5FF),
      const Color(0xFFE040FB), const Color(0xFF40C4FF),
      const Color(0xFFB388FF), const Color(0xFF80D8FF),
    ];
    return List.generate(6, (i) {
      final speed = i % 2 == 0 ? 1.0 : -1.3;
      final angle = _orbitCtrl.value * 2 * pi * speed + (i * pi / 3);
      final radius = i % 2 == 0 ? 142.0 : 110.0;
      final sz = i % 2 == 0 ? 9.0 : 6.0;
      return Transform.translate(
        offset: Offset(cos(angle) * radius, sin(angle) * radius),
        child: Opacity(
          opacity: CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn).value,
          child: Container(
            width: sz, height: sz,
            decoration: BoxDecoration(shape: BoxShape.circle, color: colors[i],
              boxShadow: [BoxShadow(color: colors[i].withOpacity(0.8), blurRadius: 10)]),
          ),
        ),
      );
    });
  }

  List<Widget> _buildStars(Size size, double bg) {
    final rng = Random(42);
    return List.generate(40, (i) {
      final sz = 1.0 + rng.nextDouble() * 2.0;
      final twinkle = 0.2 + 0.8 * (0.5 + 0.5 * sin(bg * 2 * pi + i * 0.7));
      return Positioned(
        left: rng.nextDouble() * size.width,
        top: rng.nextDouble() * size.height,
        child: Container(width: sz, height: sz,
          decoration: BoxDecoration(shape: BoxShape.circle,
            color: Colors.white.withOpacity((0.15 + rng.nextDouble() * 0.5) * twinkle))),
      );
    });
  }

  List<Widget> _buildParticles(Size size, double bg) {
    final rng = Random(99);
    final cols = [const Color(0xFF7C4DFF), const Color(0xFF00E5FF), const Color(0xFFE040FB)];
    return List.generate(14, (i) {
      final x = rng.nextDouble() * size.width;
      final baseY = rng.nextDouble() * size.height;
      final speed = 0.3 + rng.nextDouble() * 0.7;
      final phase = rng.nextDouble() * 2 * pi;
      final y = baseY + 22 * sin(bg * 2 * pi * speed + phase);
      final op = (0.25 + 0.45 * sin(bg * 2 * pi * speed + phase + pi / 2)).clamp(0.0, 0.7);
      return Positioned(left: x, top: y,
        child: Container(width: 3, height: 3,
          decoration: BoxDecoration(shape: BoxShape.circle,
            color: cols[i % 3].withOpacity(op),
            boxShadow: [BoxShadow(color: cols[i % 3].withOpacity(op * 0.6), blurRadius: 8)])));
    });
  }
}

// ── Custom Painters ───────────────────────────────────────────

class _HexGridPainter extends CustomPainter {
  final Color color;
  final double animValue;
  const _HexGridPainter({required this.color, required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    const hexSize = 34.0;
    const h = hexSize * 1.732;
    const w = hexSize * 2.0;

    for (double row = -1; row < size.height / h + 1; row++) {
      for (double col = -1; col < size.width / w + 1; col++) {
        final offsetX = col * w * 0.75 + (row % 2 == 0 ? 0 : w * 0.375);
        final offsetY = row * h * 0.5;
        // pulse opacity based on distance from center
        final cx = size.width / 2;
        final cy = size.height * 0.4;
        final dist = sqrt(pow(offsetX - cx, 2) + pow(offsetY - cy, 2));
        final maxDist = sqrt(pow(size.width, 2) + pow(size.height, 2)) / 2;
        final fade = (1 - (dist / maxDist)).clamp(0.0, 1.0);
        paint.color = color.withOpacity(0.2 * fade * (0.5 + 0.5 * animValue));
        _drawHex(canvas, paint, offsetX, offsetY, hexSize * 0.85);
      }
    }
  }

  void _drawHex(Canvas canvas, Paint paint, double cx, double cy, double r) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = pi / 180 * (60 * i - 30);
      final x = cx + r * cos(angle);
      final y = cy + r * sin(angle);
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override bool shouldRepaint(_HexGridPainter old) => old.animValue != animValue;
}

class _ArcPainter extends CustomPainter {
  final Color color; final double sweepAngle, strokeWidth;
  const _ArcPainter({required this.color, required this.sweepAngle, required this.strokeWidth});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromLTWH(0, 0, size.width, size.height), 0, sweepAngle, false, paint);
  }
  @override bool shouldRepaint(_) => false;
}

class _DashedRingPainter extends CustomPainter {
  final Color color;
  const _DashedRingPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 1.2..style = PaintingStyle.stroke;
    final cx = size.width / 2; final cy = size.height / 2;
    final r = size.width / 2 - 1;
    for (int i = 0; i < 20; i++) {
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        i * pi / 10, pi * 0.055, false, paint);
    }
  }
  @override bool shouldRepaint(_) => false;
}

// ── Reusable widgets ──────────────────────────────────────────

class _Blob extends StatelessWidget {
  final double x, y, size, phase, bg; final Color color;
  const _Blob(this.x, this.y, this.size, this.color, this.phase, this.bg);
  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size;
    final p = 0.85 + 0.15 * sin(bg * 2 * pi + phase);
    return Positioned(
      left: s.width * x - size / 2, top: s.height * y - size / 2,
      child: Container(width: size * p, height: size * p,
        decoration: BoxDecoration(shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color.withOpacity(0.14), color.withOpacity(0.04), Colors.transparent]))));
  }
}

class _Ripple extends StatelessWidget {
  final AnimationController ctrl; final double maxR, sw; final Color color;
  const _Ripple(this.ctrl, this.maxR, this.color, this.sw);
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: ctrl, builder: (_, __) {
    final t = ctrl.value;
    final r = maxR * t;
    if (r <= 0) return const SizedBox.shrink();
    return Container(width: r * 2, height: r * 2,
      decoration: BoxDecoration(shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity((1 - t) * 0.55), width: sw)));
  });
}

class _FeaturePill extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  const _FeaturePill(this.icon, this.label, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20),
      color: color.withOpacity(0.1), border: Border.all(color: color.withOpacity(0.35))),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 13),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11, fontWeight: FontWeight.w500)),
    ]));
}

class _GetStartedBtn extends StatefulWidget {
  final VoidCallback onTap;
  const _GetStartedBtn({required this.onTap});
  @override State<_GetStartedBtn> createState() => _GetStartedBtnState();
}
class _GetStartedBtnState extends State<_GetStartedBtn> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _g;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _g = Tween<double>(begin: 0.45, end: 1.0).animate(_c);
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _g,
    builder: (_, __) => GestureDetector(
      onTap: widget.onTap,
      child: Container(width: double.infinity, height: 62,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [Color(0xFF9D4EDD), Color(0xFF5390D9), Color(0xFF00B4D8)],
            begin: Alignment.centerLeft, end: Alignment.centerRight),
          boxShadow: [
            BoxShadow(color: const Color(0xFF7C4DFF).withOpacity(_g.value), blurRadius: 40, offset: const Offset(0, 12)),
            BoxShadow(color: const Color(0xFF00B4D8).withOpacity(_g.value * 0.5), blurRadius: 20, offset: const Offset(0, 4)),
          ]),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('Get Started', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
          const SizedBox(width: 14),
          Container(width: 34, height: 34,
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.18)),
            child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18)),
        ]),
      ),
    ));
}