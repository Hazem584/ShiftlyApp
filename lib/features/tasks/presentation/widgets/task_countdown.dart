import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import '../../domain/personal_task.dart';
import 'task_countdown_format.dart';

class TaskCountdown extends StatefulWidget {
  const TaskCountdown({
    required this.task,
    this.now,
    this.compact = false,
    super.key,
  });
  final PersonalTask task;
  final bool compact;
  final DateTime Function()? now;

  @override
  State<TaskCountdown> createState() => _TaskCountdownState();
}

class _TaskCountdownState extends State<TaskCountdown> {
  Timer? _ticker;
  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    if (!widget.task.completed) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void didUpdateWidget(covariant TaskCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.completed != widget.task.completed) _startTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = computeTaskCountdown(
      widget.task,
      widget.now?.call() ?? DateTime.now(),
    );
    if (widget.compact) return buildCompactTaskCountdown(context, data);
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(data.label),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          if (!widget.task.completed && (data.waiting || data.running))
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (data.days > 0)
                  Text(context.tr('{days} days', {'days': '${data.days}'})),
                Text(
                  data.time,
                  textDirection: TextDirection.ltr,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
