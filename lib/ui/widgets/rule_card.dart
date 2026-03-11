import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/rule_model.dart';

class RuleCard extends StatefulWidget {
  final RuleModel rule;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onRun;

  const RuleCard({
    super.key,
    required this.rule,
    required this.onTap,
    required this.onToggle,
    required this.onDelete,
    required this.onRun,
  });

  @override
  State<RuleCard> createState() => _RuleCardState();
}

class _RuleCardState extends State<RuleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _pressScale;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _pressScale = Tween<double>(begin: 1.0, end: 0.97).animate(
        CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  Color get _priorityColor {
    switch (widget.rule.priority) {
      case 1:
        return AppTheme.priorityHigh;
      case 2:
        return AppTheme.priorityMedium;
      default:
        return AppTheme.priorityLow;
    }
  }

  String get _triggerEmoji =>
      AppConstants.triggerLabels[widget.rule.trigger.type]
          ?.split(' ')
          .first ??
      '⚡';

  List<Color> get _cardGradient {
    switch (widget.rule.trigger.type) {
      case AppConstants.triggerTime:
        return [const Color(0xFF1A1535), const Color(0xFF1E1A40)];
      case AppConstants.triggerBattery:
        return [const Color(0xFF1A2510), const Color(0xFF1C2A12)];
      case AppConstants.triggerConnectivity:
        return [const Color(0xFF0F2030), const Color(0xFF122535)];
      case AppConstants.triggerManual:
        return [const Color(0xFF251A10), const Color(0xFF2A1C12)];
      default:
        return [AppTheme.cardBg, AppTheme.cardBgLight];
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _pressCtrl.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _pressCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _pressCtrl.reverse();
      },
      child: AnimatedBuilder(
        animation: _pressScale,
        builder: (_, child) =>
            Transform.scale(scale: _pressScale.value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: _cardGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: widget.rule.isEnabled
                  ? AppTheme.primary.withOpacity(0.15)
                  : Colors.white.withOpacity(0.05),
              width: 1.2,
            ),
            boxShadow: widget.rule.isEnabled
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              // Priority strip
              Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.rule.isEnabled
                        ? [_priorityColor, _priorityColor.withOpacity(0.3)]
                        : [
                            Colors.white.withOpacity(0.1),
                            Colors.transparent
                          ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22)),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Trigger icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: widget.rule.isEnabled
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF7C4DFF),
                                      Color(0xFF00B0D8)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: widget.rule.isEnabled
                                ? null
                                : AppTheme.surface,
                            boxShadow: widget.rule.isEnabled
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primary
                                          .withOpacity(0.4),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : [],
                          ),
                          child: Center(
                            child: Text(_triggerEmoji,
                                style: const TextStyle(fontSize: 22)),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Name + desc
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.rule.name,
                                      style: TextStyle(
                                        color: widget.rule.isEnabled
                                            ? AppTheme.textPrimary
                                            : AppTheme.textSecondary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (widget.rule.hasConflict)
                                    Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.warning
                                            .withOpacity(0.15),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                        border: Border.all(
                                            color: AppTheme.warning
                                                .withOpacity(0.4),
                                            width: 1),
                                      ),
                                      child: const Text('⚠️',
                                          style: TextStyle(fontSize: 10)),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                widget.rule.description.isNotEmpty
                                    ? widget.rule.description
                                    : AppConstants.triggerDescriptions[
                                            widget.rule.trigger.type] ??
                                        '',
                                style: const TextStyle(
                                    color: AppTheme.textHint, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Toggle
                        Transform.scale(
                          scale: 0.85,
                          child: Switch(
                            value: widget.rule.isEnabled,
                            onChanged: (_) => widget.onToggle(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Bottom row
                    Row(
                      children: [
                        // Priority badge
                        _PriorityBadge(priority: widget.rule.priority),
                        const SizedBox(width: 8),
                        // Runs count
                        _InfoChip(
                          icon: Icons.play_circle_outline,
                          label: '${widget.rule.executionCount} runs',
                        ),
                        const SizedBox(width: 8),
                        // Actions count
                        _InfoChip(
                          icon: Icons.bolt_outlined,
                          label: '${widget.rule.actions.length} actions',
                        ),
                        const Spacer(),
                        // Run button
                        _IconActionBtn(
                          icon: Icons.play_arrow_rounded,
                          color: AppTheme.success,
                          onTap: widget.onRun,
                        ),
                        const SizedBox(width: 4),
                        // Delete button
                        _IconActionBtn(
                          icon: Icons.delete_outline_rounded,
                          color: AppTheme.error,
                          onTap: widget.onDelete,
                        ),
                      ],
                    ),

                    if (widget.rule.lastExecutedAt != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 11,
                              color: AppTheme.textHint.withOpacity(0.6)),
                          const SizedBox(width: 4),
                          Text(
                            'Last run ${AppDateUtils.timeAgo(widget.rule.lastExecutedAt!)}',
                            style: TextStyle(
                                color: AppTheme.textHint.withOpacity(0.6),
                                fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final int priority;
  const _PriorityBadge({required this.priority});

  Color get _color {
    switch (priority) {
      case 1:
        return AppTheme.priorityHigh;
      case 2:
        return AppTheme.priorityMedium;
      default:
        return AppTheme.priorityLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border:
            Border.all(color: _color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, color: _color, size: 10),
          const SizedBox(width: 4),
          Text(
            AppConstants.priorityLabels[priority] ?? 'Med',
            style: TextStyle(
                color: _color,
                fontSize: 10,
                fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppTheme.textHint),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.textHint, fontSize: 10)),
        ],
      ),
    );
  }
}

class _IconActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconActionBtn(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border:
              Border.all(color: color.withOpacity(0.25), width: 1),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }
}
