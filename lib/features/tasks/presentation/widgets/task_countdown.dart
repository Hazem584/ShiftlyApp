import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import '../../domain/personal_task.dart';

class TaskCountdown extends StatefulWidget {
  const TaskCountdown({required this.task, this.now, super.key});
  final PersonalTask task;
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
    final task = widget.task;
    final now = widget.now?.call() ?? DateTime.now();
    final due = task.nextDueAt(now);
    final end = task.durationMinutes == null
        ? null
        : due.add(Duration(minutes: task.durationMinutes!));
    final waiting = due.isAfter(now);
    final target = waiting ? due : end;
    final running = !waiting && (target?.isAfter(now) ?? false);
    final label = task.completed
        ? 'Task completed'
        : waiting
        ? 'Starts in'
        : running
        ? 'Time remaining'
        : task.endsAt == null
        ? 'Task is due'
        : 'Task time ended';
    final seconds = target == null
        ? 0
        : (target.difference(now).inMilliseconds / 1000).ceil().clamp(
            0,
            315576000000,
          );
    final days = seconds ~/ 86400;
    final time =
        '${((seconds ~/ 3600) % 24).toString().padLeft(2, '0')}:'
        '${((seconds ~/ 60) % 60).toString().padLeft(2, '0')}:'
        '${(seconds % 60).toString().padLeft(2, '0')}';
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
            context.tr(label),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          if (!task.completed && (waiting || running))
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (days > 0)
                  Text(context.tr('{days} days', {'days': '$days'})),
                Text(
                  time,
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
