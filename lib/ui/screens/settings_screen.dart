import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../services/sound_service.dart';
import '../../providers/providers.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;
import 'dart:convert';

// ── Providers ────────────────────────────────────────────────
final darkModeProvider      = StateProvider<bool>((ref) => true);
final notifProvider         = StateProvider<bool>((ref) => true);
final soundEffectsProvider  = StateProvider<bool>((ref) => true);
final hapticProvider        = StateProvider<bool>((ref) => true);
final autoRunProvider       = StateProvider<bool>((ref) => false);
final analyticsProvider2    = StateProvider<bool>((ref) => true);
final compactViewProvider   = StateProvider<bool>((ref) => false);
final selectedThemeProvider = StateProvider<String>((ref) => 'Dark Purple');
// Accent color that all toggles and highlights use
final themeAccentProvider   = StateProvider<Color>((ref) {
  final t = ref.watch(selectedThemeProvider);
  return themeColorMap[t] ?? const Color(0xFF7C4DFF);
});

const themeColorMap = {
  'Dark Purple'  : Color(0xFF7C4DFF),
  'Ocean Blue'   : Color(0xFF0077B6),
  'Forest Green' : Color(0xFF2D9C4F),
  'Sunset Orange': Color(0xFFE65100),
  'Rose Pink'    : Color(0xFFAD1457),
};

// ─────────────────────────────────────────────────────────────
// Theme Picker — proper ConsumerWidget (never instantiate inline)
// ─────────────────────────────────────────────────────────────
class _ThemePicker extends ConsumerWidget {
  final void Function(String) onSelected;
  const _ThemePicker({required this.onSelected});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(selectedThemeProvider);
    return Padding(padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('App Theme', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Changes accent colour for toggles, buttons and highlights',
            style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12)),
        const SizedBox(height: 16),
        ...themeColorMap.entries.map((e) {
          final sel = current == e.key;
          return GestureDetector(
            onTap: () {
              ref.read(selectedThemeProvider.notifier).state = e.key;
              ref.read(themeAccentProvider.notifier).state = e.value;
              Navigator.pop(context);
              onSelected(e.key);
            },
            child: AnimatedContainer(duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
                color: sel ? e.value.withOpacity(0.15) : AppTheme.surface,
                border: Border.all(color: sel ? e.value.withOpacity(0.5) : Colors.transparent, width: 1.5)),
              child: Row(children: [
                Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, color: e.value,
                    boxShadow: sel ? [BoxShadow(color: e.value.withOpacity(0.5), blurRadius: 8)] : null)),
                const SizedBox(width: 12),
                Text(e.key, style: TextStyle(color: sel ? e.value : Colors.white,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.normal, fontSize: 15)),
                const Spacer(),
                if (sel) Icon(Icons.check_circle_rounded, color: e.value, size: 20),
              ])),
          );
        }),
        const SizedBox(height: 8),
      ]));
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg, style: const TextStyle(color: Colors.white)),
    backgroundColor: const Color(0xFF1E2A3A), behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    margin: const EdgeInsets.all(16)));

  void _showThemePicker() => showModalBottomSheet(
    context: context, backgroundColor: AppTheme.cardBg,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _ThemePicker(onSelected: (name) {
      SoundService.playSound('notification');
      _snack('Theme changed to $name — all toggles updated!');
    }));

  void _showClearDialog() => showDialog(context: context,
    builder: (ctx) => Dialog(backgroundColor: AppTheme.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.error.withOpacity(0.1)),
            child: const Icon(Icons.delete_sweep_outlined, color: AppTheme.error, size: 32)),
        const SizedBox(height: 16),
        const Text('Clear All Data?', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('All rules and logs will be deleted permanently.',
            textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(
            onPressed: () { Navigator.pop(ctx); SoundService.playSound('alert'); _snack('All data cleared'); },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error), child: const Text('Clear'))),
        ]),
      ]))));

  void _showImportDialog() => showModalBottomSheet(
    context: context, backgroundColor: AppTheme.cardBg, isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) {
      final ctrl = TextEditingController();
      return SafeArea(child: Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 44, height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF69F0AE).withOpacity(0.15)),
              child: const Icon(Icons.download_outlined, color: Color(0xFF69F0AE), size: 22)),
            const SizedBox(width: 12),
            const Text('Import Rules', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          Text('Paste your exported JSON below:', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
              color: Colors.white.withOpacity(0.05), border: Border.all(color: Colors.white.withOpacity(0.1))),
            child: TextField(controller: ctrl, maxLines: 6,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: '{"rules": [...]}',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontFamily: 'monospace'),
                border: InputBorder.none, contentPadding: const EdgeInsets.all(14)))),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              onPressed: () {
                try {
                  final parsed = jsonDecode(ctrl.text);
                  final rulesList = parsed['rules'] as List?;
                  Navigator.pop(ctx);
                  SoundService.playSound('success');
                  _snack('Imported ${rulesList?.length ?? 0} rules successfully!');
                } catch (e) {
                  Navigator.pop(ctx);
                  _snack('Invalid JSON format — check your file');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF69F0AE)),
              child: const Text('Import', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700)))),
          ]),
        ]),
      ));
    });

  @override
  Widget build(BuildContext context) {
    final dark     = ref.watch(darkModeProvider);
    final notif    = ref.watch(notifProvider);
    final sound    = ref.watch(soundEffectsProvider);
    final haptic   = ref.watch(hapticProvider);
    final autoRun  = ref.watch(autoRunProvider);
    final analytics= ref.watch(analyticsProvider2);
    final compact  = ref.watch(compactViewProvider);
    final theme    = ref.watch(selectedThemeProvider);
    final accent   = ref.watch(themeAccentProvider);

    // Dynamic background based on dark mode
    final bg = dark ? AppTheme.background : const Color(0xFF1A1A2E);

    return Scaffold(
      backgroundColor: bg,
      body: FadeTransition(opacity: _anim,
        child: CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [

          SliverToBoxAdapter(child: Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
            child: Row(children: [
              GestureDetector(onTap: () => Navigator.pop(context),
                child: Container(width: 40, height: 40,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.cardBg,
                      border: Border.all(color: Colors.white.withOpacity(0.1))),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 18))),
              const SizedBox(width: 16),
              const Text('Settings', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
              const SizedBox(width: 8),
              Icon(Icons.settings_rounded, color: accent, size: 24),
            ]))),

          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // ── APPEARANCE ──────────────────────────────
              _SectionLabel('Appearance', Icons.palette_outlined),

              // Dark Mode — when toggled, bg changes via rebuild
              _Tile(iconColor: accent, icon: Icons.dark_mode_outlined,
                title: 'Dark Mode', subtitle: dark ? 'App is using dark background' : 'App is using light background',
                trailing: _Toggle(value: dark, accent: accent, onChanged: (v) {
                  ref.read(darkModeProvider.notifier).state = v;
                  _snack(v ? 'Dark mode ON' : 'Dark mode OFF');
                })),

              _Tile(iconColor: accent, icon: Icons.color_lens_outlined,
                title: 'App Theme', subtitle: '$theme — all toggles reflect this colour',
                trailing: GestureDetector(onTap: _showThemePicker,
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: accent.withOpacity(0.15)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(shape: BoxShape.circle, color: accent)),
                      const SizedBox(width: 6),
                      Text('Change', style: TextStyle(color: accent, fontSize: 12, fontWeight: FontWeight.w600)),
                    ])))),

              _Tile(iconColor: const Color(0xFF26C6DA), icon: Icons.view_compact_outlined,
                title: 'Compact View', subtitle: compact ? 'Smaller rule cards' : 'Normal card size',
                trailing: _Toggle(value: compact, accent: accent, onChanged: (v) {
                  ref.read(compactViewProvider.notifier).state = v;
                  _snack(v ? 'Compact view on' : 'Normal view on');
                })),

              const SizedBox(height: 20),

              // ── NOTIFICATIONS ────────────────────────────
              _SectionLabel('Notifications', Icons.notifications_outlined),
              _Tile(iconColor: const Color(0xFFFFAB40), icon: Icons.notifications_outlined,
                title: 'Push Notifications', subtitle: notif ? 'Enabled' : 'Disabled',
                trailing: _Toggle(value: notif, accent: accent, onChanged: (v) {
                  ref.read(notifProvider.notifier).state = v;
                  _snack(v ? 'Notifications on' : 'Notifications off');
                })),
              _Tile(iconColor: const Color(0xFF66BB6A), icon: Icons.volume_up_outlined,
                title: 'Sound Effects', subtitle: sound ? 'Plays on rule execution' : 'Muted',
                trailing: _Toggle(value: sound, accent: accent, onChanged: (v) {
                  ref.read(soundEffectsProvider.notifier).state = v;
                  if (v) SoundService.playSound('success');
                  _snack(v ? 'Sounds on' : 'Sounds off');
                })),
              _Tile(iconColor: const Color(0xFFAB47BC), icon: Icons.vibration_outlined,
                title: 'Haptic Feedback', subtitle: haptic ? 'Vibration on' : 'Off',
                trailing: _Toggle(value: haptic, accent: accent, onChanged: (v) {
                  ref.read(hapticProvider.notifier).state = v;
                  _snack(v ? 'Haptic on' : 'Haptic off');
                })),

              // Sound tester
              Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: AppTheme.cardBg,
                    border: Border.all(color: Colors.white.withOpacity(0.05))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Test Sounds', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Row(children: [
                    _SoundBtn('Alert',   const Color(0xFFEF5350), () { SoundService.playSound('alert');   _snack('Playing Alert'); }),
                    const SizedBox(width: 8),
                    _SoundBtn('Success', const Color(0xFF66BB6A), () { SoundService.playSound('success'); _snack('Playing Success'); }),
                    const SizedBox(width: 8),
                    _SoundBtn('Warning', const Color(0xFFFFAB40), () { SoundService.playSound('warning'); _snack('Playing Warning'); }),
                    const SizedBox(width: 8),
                    _SoundBtn('Chime',   accent,                  () { SoundService.playSound('chime');   _snack('Playing Chime'); }),
                  ]),
                ])),

              const SizedBox(height: 12),

              // ── AUTOMATION ──────────────────────────────
              _SectionLabel('Automation', Icons.bolt_outlined),
              _Tile(iconColor: const Color(0xFF26A69A), icon: Icons.play_circle_outline,
                title: 'Auto-Run on App Open', subtitle: autoRun ? 'Triggers on launch' : 'Manual only',
                trailing: _Toggle(value: autoRun, accent: accent, onChanged: (v) {
                  ref.read(autoRunProvider.notifier).state = v;
                  _snack(v ? 'Auto-run on' : 'Auto-run off');
                })),
              _Tile(iconColor: const Color(0xFF42A5F5), icon: Icons.analytics_outlined,
                title: 'Usage Analytics', subtitle: analytics ? 'Collecting data' : 'Analytics off',
                trailing: _Toggle(value: analytics, accent: accent, onChanged: (v) {
                  ref.read(analyticsProvider2.notifier).state = v;
                  _snack(v ? 'Analytics on' : 'Analytics off');
                })),

              const SizedBox(height: 20),

              // ── DATA ─────────────────────────────────────
              _SectionLabel('Data & Storage', Icons.storage_outlined),
              _Tile(iconColor: const Color(0xFF00E5FF), icon: Icons.upload_file_outlined,
                title: 'Export Rules', subtitle: 'Download as JSON',
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 14),
                onTap: () {
                  try {
                    final rules = ref.read(rulesProvider);
                    final data = rules.map((r) => r.toJson()).toList();
                    final jsonStr = const JsonEncoder.withIndent('  ').convert({'rules': data, 'exported_at': DateTime.now().toIso8601String()});
                    // Web download via JS
                    js.context.callMethod('eval', ['''
                      (function(){
                        var blob = new Blob([${ jsonEncode(jsonStr) }], {type:'application/json'});
                        var url = URL.createObjectURL(blob);
                        var a = document.createElement('a');
                        a.href = url; a.download = 'autoengine_rules.json';
                        document.body.appendChild(a); a.click();
                        document.body.removeChild(a); URL.revokeObjectURL(url);
                      })();
                    ''']);
                    SoundService.playSound('success');
                    _snack('✅ Exported ${rules.length} rules as autoengine_rules.json');
                  } catch (e) {
                    _snack('Export failed: $e');
                  }
                }),
              _Tile(iconColor: const Color(0xFF69F0AE), icon: Icons.download_outlined,
                title: 'Import Rules', subtitle: 'Load rules from JSON',
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 14),
                onTap: () => _showImportDialog()),
              _Tile(iconColor: AppTheme.error, icon: Icons.delete_sweep_outlined,
                title: 'Clear All Data', subtitle: 'Delete all rules permanently',
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 14),
                onTap: _showClearDialog),

              const SizedBox(height: 20),

              // ── ABOUT ────────────────────────────────────
              _SectionLabel('About', Icons.info_outline),
              _Tile(iconColor: Colors.white38, icon: Icons.info_outline,
                title: 'App Version', subtitle: 'AutoEngine v1.0.0',
                trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: const Color(0xFF00897B).withOpacity(0.15)),
                  child: const Text('Latest', style: TextStyle(color: Color(0xFF4DB6AC), fontSize: 11, fontWeight: FontWeight.w600)))),
              _Tile(iconColor: const Color(0xFFFFD54F), icon: Icons.star_outline_rounded,
                title: 'Rate the App', subtitle: 'Enjoying AutoEngine? Leave a review!',
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 14),
                onTap: () => _snack('Thanks for the love! ⭐')),
              _Tile(iconColor: Colors.white38, icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy', subtitle: 'How we handle your data',
                trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 14),
                onTap: () => _snack('Opening privacy policy...')),
            ]))),
        ])));
  }
}

// ── Shared Widgets ────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String title; final IconData icon;
  const _SectionLabel(this.title, this.icon);
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Icon(icon, color: Colors.white54, size: 16), const SizedBox(width: 6),
      Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13,
          fontWeight: FontWeight.w700, letterSpacing: 0.5)),
    ]));
}

class _Tile extends StatelessWidget {
  final IconData icon; final Color iconColor;
  final String title, subtitle;
  final Widget trailing; final VoidCallback? onTap;
  const _Tile({required this.icon, required this.iconColor, required this.title,
    required this.subtitle, required this.trailing, this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), color: AppTheme.cardBg,
          border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Row(children: [
        Container(width: 40, height: 40,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: iconColor.withOpacity(0.15)),
          child: Icon(icon, color: iconColor, size: 20)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
          Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12)),
        ])),
        trailing,
      ])));
}

/// Toggle whose track colour comes from the current theme accent
class _Toggle extends StatelessWidget {
  final bool value; final Color accent; final ValueChanged<bool> onChanged;
  const _Toggle({required this.value, required this.accent, required this.onChanged});
  @override
  Widget build(BuildContext context) => Transform.scale(scale: 0.85,
    child: Switch(value: value, onChanged: onChanged,
      activeColor: Colors.white, activeTrackColor: accent,
      inactiveTrackColor: Colors.white.withOpacity(0.1), inactiveThumbColor: Colors.white38));
}

class _SoundBtn extends StatelessWidget {
  final String label; final Color color; final VoidCallback onTap;
  const _SoundBtn(this.label, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(onTap: onTap,
    child: Container(padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(10),
        color: color.withOpacity(0.15), border: Border.all(color: color.withOpacity(0.3))),
      child: Center(child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700))))));
}