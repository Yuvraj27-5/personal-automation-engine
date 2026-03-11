import '../../data/models/trigger_model.dart';
import 'base_trigger.dart';

// ── 1. TIME TRIGGER ──────────────────────────────────────────
class TimeTrigger extends BaseTrigger {
  const TimeTrigger(TriggerModel model) : super(model);

  @override
  Future<bool> shouldFire() async {
    final target = model.parameters['time'] as String? ?? '08:00';
    final parts = target.split(':');
    final now = DateTime.now();
    return now.hour == int.parse(parts[0]) && now.minute == int.parse(parts[1]);
  }

  @override
  String get summary => 'Every day at ${model.parameters['time'] ?? '08:00'}';
}

// ── 2. APP OPEN TRIGGER ──────────────────────────────────────
class AppOpenTrigger extends BaseTrigger {
  const AppOpenTrigger(TriggerModel model) : super(model);

  @override
  Future<bool> shouldFire() async => true;

  @override
  String get summary => 'Every time the app is opened';
}

// ── 3. MANUAL TRIGGER ────────────────────────────────────────
class ManualTrigger extends BaseTrigger {
  const ManualTrigger(TriggerModel model) : super(model);

  @override
  Future<bool> shouldFire() async => true;

  @override
  String get summary => 'Manually triggered by user';
}

// ── 4. BATTERY TRIGGER (stub on web) ─────────────────────────
class BatteryTrigger extends BaseTrigger {
  const BatteryTrigger(TriggerModel model) : super(model);

  @override
  Future<bool> shouldFire() async {
    // Battery API not available on web — simulate as true for demo
    return true;
  }

  @override
  String get summary {
    final t = model.parameters['threshold'] ?? 20;
    final d = model.parameters['direction'] ?? 'below';
    return 'When battery is $d $t%';
  }
}

// ── 5. CONNECTIVITY TRIGGER (stub on web) ────────────────────
class ConnectivityTrigger extends BaseTrigger {
  const ConnectivityTrigger(TriggerModel model) : super(model);

  @override
  Future<bool> shouldFire() async => true;

  @override
  String get summary {
    final state = model.parameters['state'] ?? 'connected';
    return 'When WiFi is $state';
  }
}

// ── 6. INTERVAL TRIGGER ──────────────────────────────────────
class IntervalTrigger extends BaseTrigger {
  const IntervalTrigger(TriggerModel model) : super(model);

  @override
  Future<bool> shouldFire() async => true;

  @override
  String get summary {
    final mins = model.parameters['intervalMinutes'] ?? 30;
    return 'Every $mins minutes';
  }
}
