import '../../data/models/trigger_model.dart';

abstract class BaseTrigger {
  final TriggerModel model;
  const BaseTrigger(this.model);

  /// Returns true if this trigger should fire right now
  Future<bool> shouldFire();

  /// Human-readable summary of this trigger's config
  String get summary;

  static BaseTrigger from(TriggerModel model) {
    // Factory resolved in automation_engine.dart
    throw UnimplementedError();
  }
}
