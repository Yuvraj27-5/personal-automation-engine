import '../../data/models/rule_model.dart';

class ConflictResult {
  final bool hasConflict;
  final String message;
  final List<String> conflictingRuleIds;

  const ConflictResult({
    required this.hasConflict,
    required this.message,
    required this.conflictingRuleIds,
  });
}

class ConflictDetector {
  /// Check if a rule conflicts with any existing rules
  static ConflictResult detect(RuleModel newRule, List<RuleModel> existingRules) {
    final conflicts = <String>[];
    final messages = <String>[];

    for (final existing in existingRules) {
      if (existing.id == newRule.id) continue;
      if (!existing.isEnabled) continue;

      // Same trigger type
      if (existing.trigger.type == newRule.trigger.type) {
        // Same trigger parameters — could collide
        if (_mapsEqual(existing.trigger.parameters, newRule.trigger.parameters)) {
          conflicts.add(existing.id);
          messages.add(
              '"${existing.name}" has the same trigger with identical parameters.');
        }

        // Same trigger, overlapping actions of same type
        final sharedActionTypes = existing.actions
            .map((a) => a.type)
            .toSet()
            .intersection(newRule.actions.map((a) => a.type).toSet());

        if (sharedActionTypes.isNotEmpty &&
            !conflicts.contains(existing.id)) {
          conflicts.add(existing.id);
          messages.add(
              '"${existing.name}" shares trigger type and action types: ${sharedActionTypes.join(', ')}');
        }
      }
    }

    if (conflicts.isEmpty) {
      return const ConflictResult(
          hasConflict: false, message: '', conflictingRuleIds: []);
    }

    return ConflictResult(
      hasConflict: true,
      message: messages.join('\n'),
      conflictingRuleIds: conflicts,
    );
  }

  static bool _mapsEqual(Map a, Map b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key].toString() != b[key]?.toString()) return false;
    }
    return true;
  }
}
