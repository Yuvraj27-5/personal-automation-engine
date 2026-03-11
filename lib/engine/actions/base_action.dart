import '../../data/models/action_model.dart';

abstract class BaseAction {
  final ActionModel model;
  const BaseAction(this.model);

  /// Execute the action. Returns a result message.
  Future<String> execute();

  /// Human-readable summary
  String get summary;
}
