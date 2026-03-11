import 'dart:async';
import 'package:flutter/material.dart';
import '../data/models/rule_model.dart';
import '../data/models/log_model.dart';
import '../engine/automation_engine.dart';
import '../core/constants/app_constants.dart';
import '../services/firebase_service.dart';

/// Automatically fires rules based on their trigger types
class AutoTriggerService {
  final AutomationEngine engine;
  final List<RuleModel> Function() getRules;
  final Function(LogModel) onLog;
  final BuildContext Function() getContext;

  Timer? _minuteTimer;
  Timer? _intervalTimer;
  final Map<String, DateTime> _lastIntervalRun = {};
  bool _appOpenDone = false;

  AutoTriggerService({
    required this.engine,
    required this.getRules,
    required this.onLog,
    required this.getContext,
  });

  /// Call this when the app starts
  void start() {
    _fireAppOpenRules();
    _startMinuteTimer();
    _startIntervalTimer();
  }

  void stop() {
    _minuteTimer?.cancel();
    _intervalTimer?.cancel();
  }

  // ── App Open ─────────────────────────────────────────────
  void _fireAppOpenRules() async {
    if (_appOpenDone) return;
    _appOpenDone = true;
    await Future.delayed(const Duration(seconds: 2));
    final rules = getRules().where((r) =>
      r.isEnabled && r.trigger.type == AppConstants.triggerAppOpen).toList();
    for (final rule in rules) {
      await _execute(rule, 'App opened');
    }
  }

  // ── Time Trigger — checks every minute ───────────────────
  void _startMinuteTimer() {
    // Fire immediately then every minute
    _checkTimeTriggers();
    _minuteTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkTimeTriggers();
    });
  }

  void _checkTimeTriggers() async {
    final now = DateTime.now();
    final rules = getRules().where((r) =>
      r.isEnabled && r.trigger.type == AppConstants.triggerTime).toList();
    for (final rule in rules) {
      final timeStr = rule.trigger.parameters['time'] as String? ?? '08:00';
      final parts = timeStr.split(':');
      if (parts.length < 2) continue;
      final targetHour = int.tryParse(parts[0]) ?? 0;
      final targetMin  = int.tryParse(parts[1]) ?? 0;
      if (now.hour == targetHour && now.minute == targetMin) {
        await _execute(rule, 'Time trigger: $timeStr');
      }
    }
  }

  // ── Interval Trigger — checks every 30 seconds ───────────
  void _startIntervalTimer() {
    _intervalTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkIntervalTriggers();
    });
  }

  void _checkIntervalTriggers() async {
    final now = DateTime.now();
    final rules = getRules().where((r) =>
      r.isEnabled && r.trigger.type == AppConstants.triggerInterval).toList();
    for (final rule in rules) {
      final mins = rule.trigger.parameters['intervalMinutes'] as int? ?? 30;
      final lastRun = _lastIntervalRun[rule.id];
      if (lastRun == null ||
          now.difference(lastRun).inMinutes >= mins) {
        _lastIntervalRun[rule.id] = now;
        await _execute(rule, 'Interval trigger: every ${mins}m');
      }
    }
  }

  // ── Execute a rule and save log ───────────────────────────
  Future<void> _execute(RuleModel rule, String reason) async {
    try {
      // Wire display message to show snackbar
      engine.onDisplayMessage = (msg, type) {
        final ctx = getContext();
        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.message_outlined, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(rule.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                Text(msg, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            )),
          ]),
          backgroundColor: const Color(0xFF1A1A3A),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
        ));
      };

      final result = await engine.runRule(rule);
      final log = await engine.logExecution(rule, result);

      // Save to Firebase
      await FirebaseService().saveLog(log);
      onLog(log);

    } catch (e) {
      debugPrint('AutoTrigger error for rule ${rule.name}: $e');
    }
  }
}