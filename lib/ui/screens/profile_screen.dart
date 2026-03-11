import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/providers.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  bool _isEditing = false;
  final _nameCtrl  = TextEditingController(text: 'Alex');
  final _emailCtrl = TextEditingController(text: 'alex@autoengine.app');
  final _bioCtrl   = TextEditingController(text: 'Building smart automations');
  String _selectedAvatar = '🧑\u200d💻';
  final _avatars = ['🧑\u200d💻','👨\u200d🚀','🦸','🧙','👨\u200d🎓','🧑\u200d🔬','👩\u200d💻','🦊'];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, [Color bg = const Color(0xFF1E2A3A)]) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _saveProfile() {
    final name = _nameCtrl.text.trim().isEmpty ? 'User' : _nameCtrl.text.trim();
    ref.read(userNameProvider.notifier).state = name;
    setState(() => _isEditing = false);
    _snack('Profile updated!', const Color(0xFF1A3A2A));
  }

  void _showChangePassword() {
    final c1 = TextEditingController();
    final c2 = TextEditingController();
    final c3 = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        bool s1 = false, s2 = false, s3 = false;
        return StatefulBuilder(builder: (_, st) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF7C4DFF).withOpacity(0.2),
                      ),
                      child: const Icon(Icons.lock_outline, color: Color(0xFF7C4DFF), size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text('Change Password',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 20),
                  _pwField('Current Password', c1, s1, () => st(() => s1 = !s1)),
                  const SizedBox(height: 12),
                  _pwField('New Password', c2, s2, () => st(() => s2 = !s2)),
                  const SizedBox(height: 12),
                  _pwField('Confirm Password', c3, s3, () => st(() => s3 = !s3)),
                  const SizedBox(height: 10),
                  if (c2.text.isNotEmpty) _PasswordStrength(c2.text),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: ElevatedButton(
                      onPressed: () {
                        if (c2.text != c3.text) { _snack('Passwords do not match!', const Color(0xFF3A1A1A)); return; }
                        if (c2.text.length < 6) { _snack('Min 6 chars required', const Color(0xFF3A1A1A)); return; }
                        Navigator.pop(ctx);
                        _snack('Password changed!', const Color(0xFF1A3A2A));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C4DFF)),
                      child: const Text('Update'),
                    )),
                  ]),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _showBiometrics() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        bool face = false, finger = false;
        return StatefulBuilder(builder: (_, st) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00B4D8).withOpacity(0.2),
                      ),
                      child: const Icon(Icons.fingerprint, color: Color(0xFF00B4D8), size: 26),
                    ),
                    const SizedBox(width: 12),
                    const Text('Biometric Login',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 16),
                  Text('Unlock AutoEngine without your password.',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                  const SizedBox(height: 20),
                  _BioOption('Face ID', Icons.face_retouching_natural, face, (v) => st(() => face = v)),
                  const SizedBox(height: 10),
                  _BioOption('Fingerprint', Icons.fingerprint, finger, (v) => st(() => finger = v)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _snack(face || finger ? 'Biometrics enabled!' : 'Biometrics disabled',
                          const Color(0xFF1A3A2A));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B4D8),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Save',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _showTwoFactor() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        bool enabled = false;
        return StatefulBuilder(builder: (_, st) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF66BB6A).withOpacity(0.2),
                      ),
                      child: const Icon(Icons.shield_outlined, color: Color(0xFF66BB6A), size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Text('Two-Factor Auth',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ]),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: const Color(0xFF66BB6A).withOpacity(0.08),
                      border: Border.all(color: const Color(0xFF66BB6A).withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.info_outline, color: Color(0xFF66BB6A), size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        'Verify via app or SMS on each login.',
                        style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  Row(children: [
                    const Expanded(child: Text('Enable 2FA',
                      style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))),
                    Switch(
                      value: enabled,
                      onChanged: (v) => st(() => enabled = v),
                      activeColor: Colors.white,
                      activeTrackColor: const Color(0xFF66BB6A),
                      inactiveTrackColor: Colors.white12,
                      inactiveThumbColor: Colors.white38,
                    ),
                  ]),
                  if (enabled) ...[
                    const SizedBox(height: 16),
                    Row(children: const [
                      _Method(Icons.sms_outlined, 'SMS Code'),
                      SizedBox(width: 10),
                      _Method(Icons.phone_android_outlined, 'Auth App'),
                    ]),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _snack(enabled ? '2FA enabled!' : '2FA disabled', const Color(0xFF1A3A2A));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF66BB6A),
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('Save',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _showActiveSessions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Active Sessions',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _sessionTile(ctx, 'Chrome — Windows', 'Current session', Icons.computer, const Color(0xFF66BB6A), true),
                const SizedBox(height: 8),
                _sessionTile(ctx, 'Safari — iPhone', '3 days ago', Icons.phone_iphone, Colors.white54, false),
                const SizedBox(height: 8),
                _sessionTile(ctx, 'Firefox — Mac', '7 days ago', Icons.laptop_mac_outlined, Colors.white54, false),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sessionTile(BuildContext ctx, String device, String time, IconData icon, Color color, bool current) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: AppTheme.surface,
        border: Border.all(
          color: current ? const Color(0xFF66BB6A).withOpacity(0.25) : Colors.transparent,
        ),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(device, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            Text(time, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
          ],
        )),
        if (!current)
          GestureDetector(
            onTap: () => Navigator.pop(ctx),
            child: const Text('Revoke',
              style: TextStyle(color: Color(0xFFEF5350), fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        if (current)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: const Color(0xFF66BB6A).withOpacity(0.12),
            ),
            child: const Text('Active',
              style: TextStyle(color: Color(0xFF66BB6A), fontSize: 11, fontWeight: FontWeight.w600)),
          ),
      ]),
    );
  }

  void _showNotifSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final vals = <String, bool>{
          'Rule executions': true,
          'Weekly summary': true,
          'AI suggestions': false,
          'App updates': true,
        };
        return StatefulBuilder(builder: (_, st) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notification Settings',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ...vals.entries.map((e) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: AppTheme.surface,
                    ),
                    child: Row(children: [
                      Expanded(child: Text(e.key,
                        style: const TextStyle(color: Colors.white, fontSize: 14))),
                      Switch(
                        value: e.value,
                        onChanged: (v) => st(() => vals[e.key] = v),
                        activeColor: Colors.white,
                        activeTrackColor: const Color(0xFF7C4DFF),
                        inactiveTrackColor: Colors.white12,
                        inactiveThumbColor: Colors.white38,
                      ),
                    ]),
                  )),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _snack('Notification settings saved!', const Color(0xFF1A3A2A));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C4DFF),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _showBackup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Backup & Restore',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _backupTile(ctx, Icons.backup_outlined, const Color(0xFF00897B), 'Create Backup', 'Export all rules as JSON', 'Backup created!'),
                const SizedBox(height: 10),
                _backupTile(ctx, Icons.restore_outlined, const Color(0xFF0077B6), 'Restore Backup', 'Import rules from file', 'Select a backup file'),
                const SizedBox(height: 10),
                _backupTile(ctx, Icons.cloud_upload_outlined, const Color(0xFF7C4DFF), 'Cloud Sync', 'Sync across devices', 'Cloud sync coming soon!'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _backupTile(BuildContext ctx, IconData icon, Color color, String title, String subtitle, String msg) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(ctx);
        _snack(msg, const Color(0xFF1A3A2A));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppTheme.surface,
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.15)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
              Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12)),
            ],
          )),
          Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.3), size: 14),
        ]),
      ),
    );
  }

  void _showSignOut() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppTheme.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.error.withOpacity(0.1)),
                  child: const Icon(Icons.logout_rounded, color: AppTheme.error, size: 32),
                ),
                const SizedBox(height: 16),
                const Text('Sign Out?',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('You will return to the login screen.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushAndRemoveUntil(context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const LoginScreen(),
                          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
                          transitionDuration: const Duration(milliseconds: 500),
                        ),
                        (_) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
                    child: const Text('Sign Out'),
                  )),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _pwField(String hint, TextEditingController ctrl, bool show, VoidCallback toggle) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.06),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: !show,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13),
          prefixIcon: const Icon(Icons.lock_outline, color: Colors.white38, size: 18),
          suffixIcon: IconButton(
            onPressed: toggle,
            icon: Icon(show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: Colors.white38, size: 18),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allRules    = ref.watch(rulesProvider);
    final allLogs     = ref.watch(logsProvider);
    final totalRuns   = allLogs.length;
    final successRuns = allLogs.where((l) => l.success).length;
    final rate        = totalRuns > 0 ? (successRuns / totalRuns * 100).toInt() : 0;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: FadeTransition(
        opacity: _anim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [

            SliverToBoxAdapter(child: Container(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
              child: Row(children: [
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Colors.white, Color(0xFFB47CFF)]).createShader(b),
                  child: const Text('Profile',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(context, _slideRoute(const SettingsScreen())),
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle, color: AppTheme.cardBg,
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Icon(Icons.settings_outlined, color: Colors.white70, size: 22),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => _isEditing ? _saveProfile() : setState(() => _isEditing = true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: _isEditing
                        ? const LinearGradient(colors: [Color(0xFF00897B), Color(0xFF26C6DA)])
                        : null,
                      color: _isEditing ? null : AppTheme.cardBg,
                      border: _isEditing ? null : Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_isEditing ? Icons.check_rounded : Icons.edit_outlined,
                        color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(_isEditing ? 'Save' : 'Edit',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ]),
            )),

            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(children: [

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF7C4DFF).withOpacity(0.2),
                        const Color(0xFF00E5FF).withOpacity(0.08),
                      ],
                    ),
                    border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                  ),
                  child: Column(children: [
                    Stack(alignment: Alignment.bottomRight, children: [
                      Container(
                        width: 90, height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C4DFF), Color(0xFF00E5FF)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                          boxShadow: [BoxShadow(
                            color: const Color(0xFF7C4DFF).withOpacity(0.4),
                            blurRadius: 20, spreadRadius: 2,
                          )],
                        ),
                        child: Center(child: Text(_selectedAvatar,
                          style: const TextStyle(fontSize: 42))),
                      ),
                      if (_isEditing) Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, color: AppTheme.primary,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                      ),
                    ]),
                    if (_isEditing) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 50,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal, shrinkWrap: true,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemCount: _avatars.length,
                          itemBuilder: (_, i) => GestureDetector(
                            onTap: () => setState(() => _selectedAvatar = _avatars[i]),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 46, height: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _selectedAvatar == _avatars[i]
                                  ? AppTheme.primary.withOpacity(0.3) : AppTheme.cardBg,
                                border: Border.all(
                                  color: _selectedAvatar == _avatars[i]
                                    ? AppTheme.primary : Colors.transparent, width: 2),
                              ),
                              child: Center(child: Text(_avatars[i],
                                style: const TextStyle(fontSize: 22))),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    if (_isEditing) ...[
                      _EditField(ctrl: _nameCtrl, hint: 'Your name', icon: Icons.person_outline),
                      const SizedBox(height: 10),
                      _EditField(ctrl: _emailCtrl, hint: 'Email', icon: Icons.email_outlined),
                      const SizedBox(height: 10),
                      _EditField(ctrl: _bioCtrl, hint: 'Bio', icon: Icons.info_outline),
                    ] else ...[
                      Text(_nameCtrl.text,
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_emailCtrl.text,
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppTheme.primary.withOpacity(0.15),
                        ),
                        child: Text(_bioCtrl.text,
                          style: TextStyle(color: AppTheme.primary, fontSize: 12)),
                      ),
                    ],
                  ]),
                ),

                const SizedBox(height: 20),
                Row(children: [
                  _PStat('${allRules.length}', 'Rules', Icons.bolt_rounded),
                  _PStat('$totalRuns', 'Runs', Icons.play_circle_outline),
                  _PStat('$rate%', 'Success', Icons.check_circle_outline),
                  _PStat('${allRules.where((r) => r.isEnabled).length}', 'Active', Icons.circle_outlined),
                ]),
                const SizedBox(height: 20),

                const _SH('Achievements'),
                const SizedBox(height: 12),
                Wrap(spacing: 10, runSpacing: 10, children: [
                  _Achieve('🚀', 'First Rule',    'Create 1 rule',    allRules.isNotEmpty),
                  _Achieve('⚡', 'Power User',    '5+ rules',         allRules.length >= 5),
                  _Achieve('🎯', 'Trigger Happy', 'All 6 triggers',   false),
                  _Achieve('🔥', '100 Runs',      'Execute 100+',     totalRuns >= 100),
                  _Achieve('🧪', 'Scientist',     'Use Sandbox',      false),
                  _Achieve('💎', 'Master',        'All achievements', false),
                ]),
                const SizedBox(height: 20),

                const _SH('Recent Activity'),
                const SizedBox(height: 12),
                allLogs.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16), color: AppTheme.cardBg),
                      child: Center(child: Text('No activity yet',
                        style: TextStyle(color: Colors.white.withOpacity(0.4)))),
                    )
                  : Column(children: allLogs.take(4).map((log) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14), color: AppTheme.cardBg,
                        border: Border.all(color: Colors.white.withOpacity(0.05))),
                      child: Row(children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(shape: BoxShape.circle,
                            color: (log.success ? AppTheme.success : AppTheme.error).withOpacity(0.15)),
                          child: Icon(log.success ? Icons.check_rounded : Icons.close_rounded,
                            color: log.success ? AppTheme.success : AppTheme.error, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(log.ruleName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(log.message,
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        ])),
                        Text('${log.durationMs}ms',
                          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 11)),
                      ]),
                    )).toList()),
                const SizedBox(height: 20),

                const _SH('Account'),
                const SizedBox(height: 12),
                _AccTile(Icons.notifications_outlined, 'Notifications', 'On',  _showNotifSettings),
                _AccTile(Icons.lock_outline_rounded,   'Change Password','',   _showChangePassword),
                _AccTile(Icons.fingerprint,            'Biometric Login','',   _showBiometrics),
                _AccTile(Icons.shield_outlined,        'Two-Factor Auth','',   _showTwoFactor),
                _AccTile(Icons.devices_outlined,       'Active Sessions','1',  _showActiveSessions),
                _AccTile(Icons.backup_outlined,        'Backup & Restore','',  _showBackup),
                _AccTile(Icons.help_outline,           'Help & Support', '',   () => _snack('Opening support!')),
                const SizedBox(height: 16),

                GestureDetector(
                  onTap: _showSignOut,
                  child: Container(
                    width: double.infinity, height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: AppTheme.error.withOpacity(0.08),
                      border: Border.all(color: AppTheme.error.withOpacity(0.3))),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
                      Icon(Icons.logout_rounded, color: AppTheme.error, size: 18),
                      SizedBox(width: 10),
                      Text('Sign Out',
                        style: TextStyle(color: AppTheme.error, fontSize: 15, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
                const SizedBox(height: 100),
              ]),
            )),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────

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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: i < s ? c : Colors.white12)))),
      const SizedBox(width: 8),
      Text(l, style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600)),
    ]);
  }
}

class _BioOption extends StatelessWidget {
  final String label; final IconData icon;
  final bool value; final ValueChanged<bool> onChange;
  const _BioOption(this.label, this.icon, this.value, this.onChange);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: AppTheme.surface),
    child: Row(children: [
      Icon(icon, color: const Color(0xFF00B4D8), size: 22),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14))),
      Switch(value: value, onChanged: onChange,
        activeColor: Colors.white, activeTrackColor: const Color(0xFF00B4D8),
        inactiveTrackColor: Colors.white12, inactiveThumbColor: Colors.white38),
    ]),
  );
}

class _Method extends StatelessWidget {
  final IconData icon; final String label;
  const _Method(this.icon, this.label);
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      color: const Color(0xFF66BB6A).withOpacity(0.1),
      border: Border.all(color: const Color(0xFF66BB6A).withOpacity(0.25))),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: const Color(0xFF66BB6A), size: 22),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    ]),
  ));
}

class _SH extends StatelessWidget {
  final String t; const _SH(this.t);
  @override Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)));
}

class _EditField extends StatelessWidget {
  final TextEditingController ctrl; final String hint; final IconData icon;
  const _EditField({required this.ctrl, required this.hint, required this.icon});
  @override Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      color: Colors.white.withOpacity(0.06),
      border: Border.all(color: Colors.white.withOpacity(0.1))),
    child: TextField(controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.white38, size: 18),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14))));
}

class _PStat extends StatelessWidget {
  final String v, l; final IconData icon;
  const _PStat(this.v, this.l, this.icon);
  @override Widget build(BuildContext context) => Expanded(child: Container(
    margin: const EdgeInsets.symmetric(horizontal: 4),
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16), color: AppTheme.cardBg,
      border: Border.all(color: Colors.white.withOpacity(0.06))),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: AppTheme.primary, size: 18),
      const SizedBox(height: 4),
      Text(v, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      Text(l, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 10)),
    ]),
  ));
}

class _Achieve extends StatelessWidget {
  final String em, t, d; final bool unlocked;
  const _Achieve(this.em, this.t, this.d, this.unlocked);
  @override Widget build(BuildContext context) => Container(
    width: (MediaQuery.of(context).size.width - 62) / 2,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: unlocked ? AppTheme.primary.withOpacity(0.12) : AppTheme.cardBg,
      border: Border.all(
        color: unlocked ? AppTheme.primary.withOpacity(0.3) : Colors.white.withOpacity(0.05))),
    child: Row(children: [
      Text(unlocked ? em : '🔒', style: const TextStyle(fontSize: 22)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t, style: TextStyle(
          color: unlocked ? Colors.white : Colors.white38,
          fontSize: 12, fontWeight: FontWeight.w700)),
        Text(d, style: TextStyle(
          color: Colors.white.withOpacity(unlocked ? 0.5 : 0.25), fontSize: 10),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      ])),
    ]),
  );
}

class _AccTile extends StatelessWidget {
  final IconData icon; final String l, v; final VoidCallback tap;
  const _AccTile(this.icon, this.l, this.v, this.tap);
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: tap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16), color: AppTheme.cardBg,
        border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Row(children: [
        Icon(icon, color: Colors.white60, size: 20),
        const SizedBox(width: 14),
        Expanded(child: Text(l, style: const TextStyle(color: Colors.white, fontSize: 14))),
        if (v.isNotEmpty) Text(v, style: TextStyle(color: AppTheme.primary, fontSize: 13)),
        const SizedBox(width: 6),
        Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.3), size: 14),
      ]),
    ),
  );
}

PageRoute _slideRoute(Widget page) => PageRouteBuilder(
  pageBuilder: (_, __, ___) => page,
  transitionsBuilder: (_, anim, __, child) => SlideTransition(
    position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
      .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
    child: child),
  transitionDuration: const Duration(milliseconds: 350));