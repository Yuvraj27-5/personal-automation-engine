import '../../data/models/condition_model.dart';

abstract class BaseCondition {
  final ConditionModel model;
  const BaseCondition(this.model);

  /// Returns true if condition passes
  Future<bool> evaluate();

  /// Human-readable description
  String get summary;
}
