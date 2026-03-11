import '../../data/models/condition_model.dart';
import '../../core/constants/app_constants.dart';
import 'base_condition.dart';
import 'conditions.dart';

class ConditionEvaluator {
  final Map<String, int> counters;

  const ConditionEvaluator({this.counters = const {}});

  /// Evaluate a list of conditions with AND/OR chaining
  /// The 'operator' field of each condition determines how it
  /// combines with the NEXT condition.
  Future<bool> evaluate(List<ConditionModel> conditions) async {
    if (conditions.isEmpty) return true;

    bool result = await _eval(conditions[0]);

    for (int i = 0; i < conditions.length - 1; i++) {
      final op = conditions[i].operator;
      final next = await _eval(conditions[i + 1]);

      if (op == AppConstants.operatorAnd) {
        result = result && next;
      } else {
        result = result || next;
      }
    }

    return result;
  }

  Future<bool> _eval(ConditionModel model) async {
    final condition = _build(model);
    return condition.evaluate();
  }

  BaseCondition _build(ConditionModel model) {
    switch (model.type) {
      case AppConstants.conditionTimeRange:
        return TimeRangeCondition(model);
      case AppConstants.conditionDayOfWeek:
        return DayOfWeekCondition(model);
      case AppConstants.conditionCounter:
        return CounterCondition(model, counters);
      default:
        throw Exception('Unknown condition type: ${model.type}');
    }
  }

  String describeCondition(ConditionModel model) {
    return _build(model).summary;
  }
}
