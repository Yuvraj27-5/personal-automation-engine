import '../../data/models/condition_model.dart';
import '../../core/utils/date_utils.dart';
import 'base_condition.dart';

// ─────────────────────────────────────────────────────────────
// 1. TIME RANGE CONDITION
// params: { "startTime": "09:00", "endTime": "18:00" }
// ─────────────────────────────────────────────────────────────
class TimeRangeCondition extends BaseCondition {
  const TimeRangeCondition(ConditionModel model) : super(model);

  @override
  Future<bool> evaluate() async {
    final start = model.parameters['startTime'] as String? ?? '00:00';
    final end = model.parameters['endTime'] as String? ?? '23:59';
    return AppDateUtils.isTimeInRange(start, end);
  }

  @override
  String get summary {
    final s = model.parameters['startTime'] ?? '09:00';
    final e = model.parameters['endTime'] ?? '18:00';
    return 'Time is between $s and $e';
  }
}

// ─────────────────────────────────────────────────────────────
// 2. DAY OF WEEK CONDITION
// params: { "days": ["Monday", "Wednesday", "Friday"] }
// ─────────────────────────────────────────────────────────────
class DayOfWeekCondition extends BaseCondition {
  const DayOfWeekCondition(ConditionModel model) : super(model);

  @override
  Future<bool> evaluate() async {
    final days = List<String>.from(
        model.parameters['days'] as List? ?? ['Monday']);
    return AppDateUtils.isCurrentDayIn(days);
  }

  @override
  String get summary {
    final days = List<String>.from(
        model.parameters['days'] as List? ?? []);
    return 'Day is one of: ${days.join(', ')}';
  }
}

// ─────────────────────────────────────────────────────────────
// 3. COUNTER CONDITION
// params: { "countKey": "my_counter", "operator": ">=", "value": 5 }
// ─────────────────────────────────────────────────────────────
class CounterCondition extends BaseCondition {
  final Map<String, int> _counters;
  CounterCondition(ConditionModel model, this._counters) : super(model);

  @override
  Future<bool> evaluate() async {
    final key = model.parameters['countKey'] as String? ?? 'default';
    final op = model.parameters['operator'] as String? ?? '>=';
    final target = model.parameters['value'] as int? ?? 1;
    final current = _counters[key] ?? 0;

    switch (op) {
      case '>=': return current >= target;
      case '<=': return current <= target;
      case '>': return current > target;
      case '<': return current < target;
      case '==': return current == target;
      default: return false;
    }
  }

  @override
  String get summary {
    final key = model.parameters['countKey'] ?? 'counter';
    final op = model.parameters['operator'] ?? '>=';
    final val = model.parameters['value'] ?? 1;
    return 'Counter "$key" $op $val';
  }
}
