import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/conflict_detector.dart';
import '../../data/models/rule_model.dart';
import '../../data/models/trigger_model.dart';
import '../../data/models/condition_model.dart';
import '../../data/models/action_model.dart';
import '../../providers/providers.dart';
import '../widgets/glass_card.dart';

class CreateRuleScreen extends ConsumerStatefulWidget {
  final RuleModel? existingRule;
  const CreateRuleScreen({super.key, this.existingRule});

  @override
  ConsumerState<CreateRuleScreen> createState() => _CreateRuleScreenState();
}

class _CreateRuleScreenState extends ConsumerState<CreateRuleScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  int _priority = 2;

  String _triggerType = AppConstants.triggerTime;
  Map<String, dynamic> _triggerParams = {'time': '08:00'};

  final List<ConditionModel> _conditions = [];
  final List<ActionModel> _actions = [];

  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final rule = widget.existingRule;
    if (rule != null) {
      _isEditing = true;
      _nameController.text = rule.name;
      _descController.text = rule.description;
      _priority = rule.priority;
      _triggerType = rule.trigger.type;
      _triggerParams = Map.from(rule.trigger.parameters);
      _conditions.addAll(rule.conditions);
      _actions.addAll(rule.actions);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut);
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a rule name'),
        backgroundColor: AppTheme.error,
      ));
      return;
    }
    if (_actions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please add at least one action'),
        backgroundColor: AppTheme.error,
      ));
      return;
    }

    final allRules = ref.read(rulesProvider);
    final rule = RuleModel(
      id: widget.existingRule?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      description: _descController.text.trim(),
      isEnabled: widget.existingRule?.isEnabled ?? true,
      trigger: TriggerModel(type: _triggerType, parameters: _triggerParams),
      conditions: _conditions,
      actions: _actions,
      createdAt: widget.existingRule?.createdAt ?? DateTime.now(),
      priority: _priority,
      executionCount: widget.existingRule?.executionCount ?? 0,
      lastExecutedAt: widget.existingRule?.lastExecutedAt,
    );

    // Conflict detection
    final conflict = ConflictDetector.detect(rule, allRules);
    RuleModel finalRule = rule;

    if (conflict.hasConflict) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.cardBg,
          title: const Row(children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.warning),
            SizedBox(width: 8),
            Text('Conflict Detected',
                style: TextStyle(color: AppTheme.textPrimary)),
          ]),
          content: Text(
            'This rule may conflict with:\n\n${conflict.message}\n\nSave anyway?',
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warning),
              child: const Text('Save Anyway'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
      finalRule = rule.copyWith(hasConflict: true);
    }

    if (_isEditing) {
      await ref.read(rulesProvider.notifier).updateRule(finalRule);
    } else {
      await ref.read(rulesProvider.notifier).addRule(finalRule);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Rule' : 'Create Rule'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
        actions: [
          if (_currentStep == 3)
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check, color: AppTheme.success),
              label: const Text('Save',
                  style: TextStyle(color: AppTheme.success)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Step indicator
          _StepIndicator(currentStep: _currentStep),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _Step1Basics(
                  nameController: _nameController,
                  descController: _descController,
                  priority: _priority,
                  onPriorityChanged: (v) => setState(() => _priority = v),
                  onNext: _nextStep,
                ),
                _Step2Trigger(
                  triggerType: _triggerType,
                  triggerParams: _triggerParams,
                  onTriggerChanged: (type, params) => setState(() {
                    _triggerType = type;
                    _triggerParams = params;
                  }),
                  onNext: _nextStep,
                  onBack: _prevStep,
                ),
                _Step3Conditions(
                  conditions: _conditions,
                  onAdd: (c) => setState(() => _conditions.add(c)),
                  onRemove: (i) => setState(() => _conditions.removeAt(i)),
                  onNext: _nextStep,
                  onBack: _prevStep,
                ),
                _Step4Actions(
                  actions: _actions,
                  onAdd: (a) => setState(() => _actions.add(a)),
                  onRemove: (i) => setState(() => _actions.removeAt(i)),
                  onSave: _save,
                  onBack: _prevStep,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step Indicator ───────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    const steps = ['Basics', 'Trigger', 'Conditions', 'Actions'];
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(steps.length, (i) {
          final active = i == currentStep;
          final done = i < currentStep;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: active ? 36 : 28,
                        height: active ? 36 : 28,
                        decoration: BoxDecoration(
                          color: done
                              ? AppTheme.success
                              : active
                                  ? AppTheme.primary
                                  : AppTheme.surface,
                          shape: BoxShape.circle,
                          border: active
                              ? Border.all(
                                  color: AppTheme.primaryLight, width: 2)
                              : null,
                        ),
                        child: Center(
                          child: done
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 14)
                              : Text('${i + 1}',
                                  style: TextStyle(
                                      color: active
                                          ? Colors.white
                                          : AppTheme.textHint,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(steps[i],
                          style: TextStyle(
                              color: active
                                  ? AppTheme.primary
                                  : AppTheme.textHint,
                              fontSize: 10,
                              fontWeight: active
                                  ? FontWeight.w600
                                  : FontWeight.normal)),
                    ],
                  ),
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: done ? AppTheme.success : AppTheme.divider,
                      margin: const EdgeInsets.only(bottom: 20),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Step 1: Basics ───────────────────────────────────────────
class _Step1Basics extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descController;
  final int priority;
  final ValueChanged<int> onPriorityChanged;
  final VoidCallback onNext;

  const _Step1Basics({
    required this.nameController,
    required this.descController,
    required this.priority,
    required this.onPriorityChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Rule Details',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Give your rule a name and set its priority',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          TextField(
            controller: nameController,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Rule Name *',
              hintText: 'e.g. Morning Battery Check',
              prefixIcon:
                  Icon(Icons.label_outline, color: AppTheme.textHint),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: descController,
            style: const TextStyle(color: AppTheme.textPrimary),
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'What does this rule do?',
              prefixIcon:
                  Icon(Icons.notes_outlined, color: AppTheme.textHint),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Priority',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: AppConstants.priorityLabels.entries.map((e) {
              final colors = {
                1: AppTheme.priorityHigh,
                2: AppTheme.priorityMedium,
                3: AppTheme.priorityLow,
              };
              final color = colors[e.key]!;
              final selected = priority == e.key;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => onPriorityChanged(e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withOpacity(0.2)
                            : AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? color : AppTheme.divider,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.flag,
                              color: selected ? color : AppTheme.textHint,
                              size: 20),
                          const SizedBox(height: 4),
                          Text(e.value,
                              style: TextStyle(
                                  color: selected
                                      ? color
                                      : AppTheme.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onNext,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Next: Choose Trigger'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 2: Trigger ──────────────────────────────────────────
class _Step2Trigger extends StatefulWidget {
  final String triggerType;
  final Map<String, dynamic> triggerParams;
  final Function(String type, Map<String, dynamic> params) onTriggerChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _Step2Trigger({
    required this.triggerType,
    required this.triggerParams,
    required this.onTriggerChanged,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<_Step2Trigger> createState() => _Step2TriggerState();
}

class _Step2TriggerState extends State<_Step2Trigger> {
  late String _type;
  late Map<String, dynamic> _params;

  @override
  void initState() {
    super.initState();
    _type = widget.triggerType;
    _params = Map.from(widget.triggerParams);
  }

  void _update(String type, Map<String, dynamic> params) {
    setState(() {
      _type = type;
      _params = params;
    });
    widget.onTriggerChanged(type, params);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Choose Trigger',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const Text('What activates this rule?',
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          ...AppConstants.allTriggerTypes.map((type) {
            final selected = _type == type;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () => _update(type, _defaultParams(type)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.primary.withOpacity(0.15)
                        : AppTheme.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected
                          ? AppTheme.primary
                          : AppTheme.divider,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                          AppConstants.triggerLabels[type]
                                  ?.split(' ')
                                  .first ??
                              '⚡',
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppConstants.triggerLabels[type]
                                      ?.split(' ')
                                      .skip(1)
                                      .join(' ') ??
                                  type,
                              style: TextStyle(
                                  color: selected
                                      ? AppTheme.primary
                                      : AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600),
                            ),
                            Text(
                              AppConstants.triggerDescriptions[type] ?? '',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (selected)
                        const Icon(Icons.check_circle,
                            color: AppTheme.primary),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          // Parameter configuration
          _TriggerParamEditor(
            type: _type,
            params: _params,
            onChanged: (params) => _update(_type, params),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'))),
              const SizedBox(width: 12),
              Expanded(
                  child: ElevatedButton.icon(
                      onPressed: widget.onNext,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'))),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _defaultParams(String type) {
    switch (type) {
      case AppConstants.triggerTime:
        return {'time': '08:00'};
      case AppConstants.triggerBattery:
        return {'threshold': 20, 'direction': 'below'};
      case AppConstants.triggerConnectivity:
        return {'state': 'connected'};
      case AppConstants.triggerInterval:
        return {'intervalMinutes': 30};
      default:
        return {};
    }
  }
}

class _TriggerParamEditor extends StatefulWidget {
  final String type;
  final Map<String, dynamic> params;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const _TriggerParamEditor(
      {required this.type,
      required this.params,
      required this.onChanged});

  @override
  State<_TriggerParamEditor> createState() => _TriggerParamEditorState();
}

class _TriggerParamEditorState extends State<_TriggerParamEditor> {
  final _timeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _timeController.text =
        widget.params['time'] as String? ?? '08:00';
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.type) {
      case AppConstants.triggerTime:
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⚙️ Configure: Time',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextField(
                controller: _timeController,
                style:
                    const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                    labelText: 'Time (HH:MM)',
                    hintText: '08:00'),
                onChanged: (v) {
                  widget.onChanged({...widget.params, 'time': v});
                },
              ),
            ],
          ),
        );

      case AppConstants.triggerBattery:
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⚙️ Configure: Battery',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Threshold: ',
                      style:
                          TextStyle(color: AppTheme.textSecondary)),
                  Expanded(
                    child: Slider(
                      value: ((widget.params['threshold'] as int?) ??
                              20)
                          .toDouble(),
                      min: 5,
                      max: 95,
                      divisions: 18,
                      label:
                          '${widget.params['threshold'] ?? 20}%',
                      onChanged: (v) => widget.onChanged(
                          {...widget.params, 'threshold': v.toInt()}),
                    ),
                  ),
                  Text(
                      '${widget.params['threshold'] ?? 20}%',
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                children: ['below', 'above'].map((d) {
                  final sel = (widget.params['direction'] ?? 'below') == d;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(d.toUpperCase()),
                        selected: sel,
                        onSelected: (_) => widget.onChanged(
                            {...widget.params, 'direction': d}),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );

      case AppConstants.triggerConnectivity:
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⚙️ Configure: Connectivity',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children:
                    ['connected', 'disconnected'].map((s) {
                  final sel =
                      (widget.params['state'] ?? 'connected') == s;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(s),
                        selected: sel,
                        onSelected: (_) => widget.onChanged(
                            {...widget.params, 'state': s}),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );

      case AppConstants.triggerInterval:
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⚙️ Configure: Interval',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Every: ',
                      style:
                          TextStyle(color: AppTheme.textSecondary)),
                  Expanded(
                    child: Slider(
                      value: ((widget.params['intervalMinutes']
                                  as int?) ??
                              30)
                          .toDouble(),
                      min: 15,
                      max: 240,
                      divisions: 15,
                      label:
                          '${widget.params['intervalMinutes'] ?? 30} min',
                      onChanged: (v) => widget.onChanged({
                        ...widget.params,
                        'intervalMinutes': v.toInt()
                      }),
                    ),
                  ),
                  Text(
                      '${widget.params['intervalMinutes'] ?? 30}m',
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Step 3: Conditions ───────────────────────────────────────
class _Step3Conditions extends StatelessWidget {
  final List<ConditionModel> conditions;
  final ValueChanged<ConditionModel> onAdd;
  final ValueChanged<int> onRemove;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const _Step3Conditions({
    required this.conditions,
    required this.onAdd,
    required this.onRemove,
    required this.onNext,
    required this.onBack,
  });

  void _addCondition(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      shape:
          const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24))),
      builder: (_) => _ConditionPicker(onAdd: onAdd),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Conditions (Optional)',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const Text('Rule only runs if these are true',
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          if (conditions.isEmpty)
            GlassCard(
              child: Center(
                child: Column(
                  children: [
                    const Text('🔘',
                        style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 8),
                    const Text('No conditions',
                        style: TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 4),
                    const Text(
                        'Rule will always run when triggered',
                        style:
                            TextStyle(color: AppTheme.textHint, fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            ...conditions.asMap().entries.map((e) {
              final i = e.key;
              final c = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.secondary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                            child: Icon(Icons.filter_alt,
                                color: AppTheme.secondary, size: 18)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppConstants.conditionLabels[c.type] ?? c.type,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                            Text(_conditionSummary(c),
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11)),
                          ],
                        ),
                      ),
                      if (i < conditions.length - 1)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(c.operator,
                              style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: AppTheme.error, size: 18),
                        onPressed: () => onRemove(i),
                        constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _addCondition(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Condition'),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'))),
              const SizedBox(width: 12),
              Expanded(
                  child: ElevatedButton.icon(
                      onPressed: onNext,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Next'))),
            ],
          ),
        ],
      ),
    );
  }

  String _conditionSummary(ConditionModel c) {
    switch (c.type) {
      case AppConstants.conditionTimeRange:
        return '${c.parameters['startTime']} – ${c.parameters['endTime']}';
      case AppConstants.conditionDayOfWeek:
        final days = List<String>.from(c.parameters['days'] ?? []);
        return days.join(', ');
      case AppConstants.conditionCounter:
        return '${c.parameters['countKey']} ${c.parameters['operator']} ${c.parameters['value']}';
      default:
        return '';
    }
  }
}

class _ConditionPicker extends StatefulWidget {
  final ValueChanged<ConditionModel> onAdd;
  const _ConditionPicker({required this.onAdd});

  @override
  State<_ConditionPicker> createState() => _ConditionPickerState();
}

class _ConditionPickerState extends State<_ConditionPicker> {
  String _type = AppConstants.conditionTimeRange;
  String _operator = 'AND';
  String _startTime = '09:00';
  String _endTime = '18:00';
  final List<String> _selectedDays = ['Monday'];
  String _counterKey = 'my_counter';
  String _counterOp = '>=';
  int _counterVal = 1;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Condition',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Type selection
          Row(
            children: AppConstants.allConditionTypes.map((t) {
              final sel = _type == t;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(AppConstants.conditionLabels[t]!
                        .split(' ')
                        .last),
                    selected: sel,
                    onSelected: (_) => setState(() => _type = t),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Parameters
          if (_type == AppConstants.conditionTimeRange) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(labelText: 'Start'),
                    onChanged: (v) => _startTime = v,
                    controller: TextEditingController(text: _startTime),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(labelText: 'End'),
                    onChanged: (v) => _endTime = v,
                    controller: TextEditingController(text: _endTime),
                  ),
                ),
              ],
            ),
          ] else if (_type == AppConstants.conditionDayOfWeek) ...[
            Wrap(
              spacing: 6,
              children: AppConstants.weekdays.map((d) {
                final sel = _selectedDays.contains(d);
                return FilterChip(
                  label: Text(d.substring(0, 3)),
                  selected: sel,
                  onSelected: (v) => setState(() =>
                      v ? _selectedDays.add(d) : _selectedDays.remove(d)),
                );
              }).toList(),
            ),
          ] else if (_type == AppConstants.conditionCounter) ...[
            TextField(
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'Counter Key'),
              onChanged: (v) => _counterKey = v,
              controller: TextEditingController(text: _counterKey),
            ),
            const SizedBox(height: 8),
            Row(
              children: ['>=', '<=', '>', '<', '=='].map((op) {
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(op),
                    selected: _counterOp == op,
                    onSelected: (_) => setState(() => _counterOp = op),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Value: ',
                    style: TextStyle(color: AppTheme.textSecondary)),
                Expanded(
                  child: Slider(
                    value: _counterVal.toDouble(),
                    min: 1,
                    max: 100,
                    divisions: 99,
                    label: '$_counterVal',
                    onChanged: (v) =>
                        setState(() => _counterVal = v.toInt()),
                  ),
                ),
                Text('$_counterVal',
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Join with next:  ',
                  style: TextStyle(color: AppTheme.textSecondary)),
              ChoiceChip(
                  label: const Text('AND'),
                  selected: _operator == 'AND',
                  onSelected: (_) => setState(() => _operator = 'AND')),
              const SizedBox(width: 8),
              ChoiceChip(
                  label: const Text('OR'),
                  selected: _operator == 'OR',
                  onSelected: (_) => setState(() => _operator = 'OR')),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Map<String, dynamic> params;
                if (_type == AppConstants.conditionTimeRange) {
                  params = {'startTime': _startTime, 'endTime': _endTime};
                } else if (_type == AppConstants.conditionDayOfWeek) {
                  params = {'days': _selectedDays};
                } else {
                  params = {
                    'countKey': _counterKey,
                    'operator': _counterOp,
                    'value': _counterVal,
                  };
                }
                widget.onAdd(ConditionModel(
                    type: _type, parameters: params, operator: _operator));
                Navigator.pop(context);
              },
              child: const Text('Add Condition'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 4: Actions ──────────────────────────────────────────
class _Step4Actions extends StatelessWidget {
  final List<ActionModel> actions;
  final ValueChanged<ActionModel> onAdd;
  final ValueChanged<int> onRemove;
  final VoidCallback onSave;
  final VoidCallback onBack;

  const _Step4Actions({
    required this.actions,
    required this.onAdd,
    required this.onRemove,
    required this.onSave,
    required this.onBack,
  });

  void _addAction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ActionPicker(onAdd: onAdd),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Actions',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const Text('What should happen when the rule fires?',
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),
          if (actions.isEmpty)
            GlassCard(
              child: Center(
                child: Column(
                  children: const [
                    Text('⚡', style: TextStyle(fontSize: 40)),
                    SizedBox(height: 8),
                    Text('No actions added',
                        style: TextStyle(color: AppTheme.textSecondary)),
                    Text('Add at least one action',
                        style:
                            TextStyle(color: AppTheme.error, fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            ...actions.asMap().entries.map((e) {
              final i = e.key;
              final a = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            AppConstants.actionLabels[a.type]
                                    ?.split(' ')
                                    .first ??
                                '⚡',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppConstants.actionLabels[a.type]
                                      ?.split(' ')
                                      .skip(1)
                                      .join(' ') ??
                                  a.type,
                              style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13),
                            ),
                            Text(_actionSummary(a),
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: AppTheme.error, size: 18),
                        onPressed: () => onRemove(i),
                        constraints: const BoxConstraints(
                            minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _addAction(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Action'),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back'))),
              const SizedBox(width: 12),
              Expanded(
                  child: ElevatedButton.icon(
                      onPressed: onSave,
                      icon: const Icon(Icons.check),
                      label: const Text('Save Rule'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.success))),
            ],
          ),
        ],
      ),
    );
  }

  String _actionSummary(ActionModel a) {
    switch (a.type) {
      case AppConstants.actionNotification:
        return a.parameters['title'] ?? '';
      case AppConstants.actionLog:
        return a.parameters['message'] ?? '';
      case AppConstants.actionDisplayMessage:
        return a.parameters['message'] ?? '';
      case AppConstants.actionSound:
        return 'Sound: ${a.parameters['sound'] ?? 'alert'}';
      case AppConstants.actionClipboard:
        final t = a.parameters['text'] ?? '';
        return t.length > 30 ? '${t.substring(0, 30)}...' : t;
      case AppConstants.actionWebhook:
        return a.parameters['url'] ?? '';
      default:
        return '';
    }
  }
}

class _ActionPicker extends StatefulWidget {
  final ValueChanged<ActionModel> onAdd;
  const _ActionPicker({required this.onAdd});

  @override
  State<_ActionPicker> createState() => _ActionPickerState();
}

class _ActionPickerState extends State<_ActionPicker> {
  String _type = AppConstants.actionNotification;
  final _p1 = TextEditingController();
  final _p2 = TextEditingController();
  String _sound = 'alert';
  String _webhookMethod = 'GET';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Action',
                style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Action type grid
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.3,
              physics: const NeverScrollableScrollPhysics(),
              children: AppConstants.allActionTypes.map((t) {
                final sel = _type == t;
                return GestureDetector(
                  onTap: () => setState(() => _type = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppTheme.primary.withOpacity(0.2)
                          : AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: sel
                              ? AppTheme.primary
                              : AppTheme.divider,
                          width: sel ? 2 : 1),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppConstants.actionLabels[t]
                                  ?.split(' ')
                                  .first ??
                              '⚡',
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppConstants.actionLabels[t]
                                  ?.split(' ')
                                  .skip(1)
                                  .join(' ') ??
                              t,
                          style: TextStyle(
                              color: sel
                                  ? AppTheme.primary
                                  : AppTheme.textSecondary,
                              fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Params
            ..._buildParams(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addAction,
                child: const Text('Add Action'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildParams() {
    switch (_type) {
      case AppConstants.actionNotification:
        return [
          TextField(
              controller: _p1,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration:
                  const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 8),
          TextField(
              controller: _p2,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration:
                  const InputDecoration(labelText: 'Body')),
        ];
      case AppConstants.actionLog:
      case AppConstants.actionDisplayMessage:
        return [
          TextField(
              controller: _p1,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration:
                  const InputDecoration(labelText: 'Message')),
        ];
      case AppConstants.actionClipboard:
        return [
          TextField(
              controller: _p1,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration:
                  const InputDecoration(labelText: 'Text to Copy')),
        ];
      case AppConstants.actionWebhook:
        return [
          TextField(
              controller: _p1,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'URL')),
          const SizedBox(height: 8),
          Row(
            children: ['GET', 'POST'].map((m) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(m),
                  selected: _webhookMethod == m,
                  onSelected: (_) =>
                      setState(() => _webhookMethod = m),
                ),
              );
            }).toList(),
          ),
        ];
      case AppConstants.actionSound:
        return [
          Wrap(
            spacing: 8,
            children: ['alert', 'success', 'warning'].map((s) {
              return ChoiceChip(
                label: Text(s),
                selected: _sound == s,
                onSelected: (_) => setState(() => _sound = s),
              );
            }).toList(),
          ),
        ];
      default:
        return [];
    }
  }

  void _addAction() {
    Map<String, dynamic> params;
    switch (_type) {
      case AppConstants.actionNotification:
        params = {'title': _p1.text, 'body': _p2.text};
        break;
      case AppConstants.actionLog:
      case AppConstants.actionDisplayMessage:
        params = {'message': _p1.text};
        break;
      case AppConstants.actionClipboard:
        params = {'text': _p1.text};
        break;
      case AppConstants.actionWebhook:
        params = {'url': _p1.text, 'method': _webhookMethod};
        break;
      case AppConstants.actionSound:
        params = {'sound': _sound};
        break;
      default:
        params = {};
    }
    widget.onAdd(ActionModel(type: _type, parameters: params));
    Navigator.pop(context);
  }
}
