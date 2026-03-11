import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import '../../services/firebase_service.dart';
import 'home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _confCtrl  = TextEditingController();
  bool _obscure = true, _obscureConf = true, _loading = false;
  late AnimationController _anim;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _confCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppTheme.error : AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _goHome() {
    Navigator.pushAndRemoveUntil(context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ), (_) => false);
  }

  Future<void> _signUp() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      _snack('Please fill in all fields'); return;
    }
    if (_passCtrl.text != _confCtrl.text) {
      _snack('Passwords do not match'); return;
    }
    if (_passCtrl.text.length < 6) {
      _snack('Password must be at least 6 characters'); return;
    }
    setState(() => _loading = true);
    try {
      final result = await FirebaseService().signUpWithEmail(
        _emailCtrl.text.trim(), _passCtrl.text);
      await result.user?.updateDisplayName(_nameCtrl.text.trim());
      await FirebaseService().initUserProfile();
      _goHome();
    } on FirebaseAuthException catch (e) {
      _snack(_authError(e.code));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInGoogle() async {
    setState(() => _loading = true);
    try {
      final result = await FirebaseService().signInWithGoogle();
      if (result != null) {
        await FirebaseService().initUserProfile();
        _goHome();
      }
    } on FirebaseAuthException catch (e) {
      _snack(_authError(e.code));
    } catch (_) {
      _snack('Google sign-in failed. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInGitHub() async {
    setState(() => _loading = true);
    try {
      final result = await FirebaseService().signInWithGitHub();
      if (result != null) {
        await FirebaseService().initUserProfile();
        _goHome();
      }
    } on FirebaseAuthException catch (e) {
      _snack(_authError(e.code));
    } catch (_) {
      _snack('GitHub sign-in failed. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _authError(String code) {
    switch (code) {
      case 'email-already-in-use': return 'Email already in use. Try signing in.';
      case 'invalid-email': return 'Invalid email address.';
      case 'weak-password': return 'Password is too weak.';
      case 'operation-not-allowed': return 'Email sign-up is not enabled.';
      default: return 'Sign up failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: _fade,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 40),
              // Back
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.cardBg,
                    border: Border.all(color: Colors.white.withOpacity(0.1))),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18)),
              ),
              const SizedBox(height: 24),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Color(0xFFFF6B9D), Color(0xFF7C4DFF), Color(0xFF00E5FF)]).createShader(b),
                child: const Text('Create Account',
                  style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900))),
              const SizedBox(height: 8),
              Text('Join AutoEngine and start automating',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
              const SizedBox(height: 36),

              _field('Full Name', _nameCtrl, Icons.person_outline, false),
              const SizedBox(height: 14),
              _field('Email', _emailCtrl, Icons.email_outlined, false),
              const SizedBox(height: 14),
              _field('Password', _passCtrl, Icons.lock_outline, _obscure,
                suffix: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: Colors.white38, size: 20))),
              const SizedBox(height: 10),
              if (_passCtrl.text.isNotEmpty) _PasswordStrength(_passCtrl.text),
              const SizedBox(height: 14),
              _field('Confirm Password', _confCtrl, Icons.lock_outline, _obscureConf,
                suffix: IconButton(
                  onPressed: () => setState(() => _obscureConf = !_obscureConf),
                  icon: Icon(_obscureConf ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: Colors.white38, size: 20))),
              const SizedBox(height: 28),

              GestureDetector(
                onTap: _loading ? null : _signUp,
                child: Container(
                  width: double.infinity, height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(colors: [Color(0xFF7C4DFF), Color(0xFF00B4D8)]),
                    boxShadow: [BoxShadow(color: const Color(0xFF7C4DFF).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Center(child: _loading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Create Account', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))),
                ),
              ),
              const SizedBox(height: 28),

              Row(children: [
                Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('or sign up with', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12))),
                Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
              ]),
              const SizedBox(height: 24),

              Row(children: [
                Expanded(child: _socialBtn(
                  onTap: _loading ? null : _signInGoogle,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SizedBox(width: 22, height: 22, child: CustomPaint(painter: _GoogleGPainter())),
                    const SizedBox(width: 10),
                    const Text('Google', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  ]),
                )),
                const SizedBox(width: 14),
                Expanded(child: _socialBtn(
                  onTap: _loading ? null : _signInGitHub,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.code, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    const Text('GitHub', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  ]),
                )),
              ]),
              const SizedBox(height: 36),

              Center(child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: RichText(text: TextSpan(
                  text: 'Already have an account? ',
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
                  children: [TextSpan(text: 'Sign In',
                    style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700))],
                )),
              )),
              const SizedBox(height: 40),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _field(String hint, TextEditingController ctrl, IconData icon, bool obscure, {Widget? suffix}) =>
    Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.1))),
      child: TextField(
        controller: ctrl, obscureText: obscure,
        onChanged: hint == 'Password' ? (_) => setState(() {}) : null,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        keyboardType: hint == 'Email' ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.35)),
          prefixIcon: Icon(icon, color: Colors.white38, size: 20),
          suffixIcon: suffix,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18))),
    );

  Widget _socialBtn({required Widget child, VoidCallback? onTap}) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.07),
          border: Border.all(color: Colors.white.withOpacity(0.1))),
        child: child),
    );
}

class _PasswordStrength extends StatelessWidget {
  final String pw;
  const _PasswordStrength(this.pw);
  @override
  Widget build(BuildContext context) {
    int s = 0;
    if (pw.length >= 8) s++;
    if (pw.contains(RegExp(r'[A-Z]'))) s++;
    if (pw.contains(RegExp(r'[0-9]'))) s++;
    if (pw.contains(RegExp(r'[!@#$%^&*]'))) s++;
    final cols = [const Color(0xFFEF5350), const Color(0xFFFFAB40), const Color(0xFF66BB6A), const Color(0xFF00E5FF)];
    final lbls = ['Weak', 'Fair', 'Good', 'Strong'];
    final c = s > 0 ? cols[s - 1] : Colors.white24;
    final l = s > 0 ? lbls[s - 1] : 'Too short';
    return Row(children: [
      ...List.generate(4, (i) => Expanded(child: Container(
        margin: const EdgeInsets.only(right: 4), height: 4,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(2), color: i < s ? c : Colors.white12)))),
      const SizedBox(width: 8),
      Text(l, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
  }
}

class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2, r = size.width / 2;
    final outerR = r, innerR = r * 0.72;
    void ring(double startDeg, double sweepDeg, Color color) {
      final path = Path();
      final outerRect = Rect.fromCircle(center: Offset(cx, cy), radius: outerR);
      final innerRect = Rect.fromCircle(center: Offset(cx, cy), radius: innerR);
      final s = startDeg * 3.14159 / 180, sw = sweepDeg * 3.14159 / 180;
      path.arcTo(outerRect, s, sw, true);
      path.arcTo(innerRect, s + sw, -sw, false);
      path.close();
      canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill..isAntiAlias = true);
    }
    ring(-102, -150, const Color(0xFFEA4335));
    ring(-102,  106, const Color(0xFF4285F4));
    ring( 190,   75, const Color(0xFFFBBC05));
    ring(  91,  101, const Color(0xFF34A853));
    final barTop = cy - r * 0.15, barBottom = cy + r * 0.15;
    canvas.drawRect(Rect.fromLTRB(cx - r * 0.07, barTop, cx + outerR + 1, barBottom),
      Paint()..color = const Color(0xFF4285F4)..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(cx, cy), innerR, Paint()..color = const Color(0xFF111827)..style = PaintingStyle.fill);
    final gap = Path()
      ..moveTo(cx, cy)
      ..arcTo(Rect.fromCircle(center: Offset(cx, cy), radius: outerR + 1), -10 * 3.14159 / 180, -85 * 3.14159 / 180, false)
      ..lineTo(cx, cy)..close();
    canvas.drawPath(gap, Paint()..color = const Color(0xFF111827)..style = PaintingStyle.fill);
  }
  @override bool shouldRepaint(_) => false;
}