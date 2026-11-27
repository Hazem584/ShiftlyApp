import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import '../../domain/personal_task.dart';

class TaskCountdownData {
  const TaskCountdownData({
    required this.waiting,
    required this.running,
    required this.label,
    required this.seconds,
    required this.days,
    required this.time,
  });
  final bool waiting, running;
  final String label, time;
  final int seconds, days;
}

TaskCountdownData computeTaskCountdown(PersonalTask task, DateTime now) {
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
  return TaskCountdownData(
    waiting: waiting,
    running: running,
    label: label,
    seconds: seconds,
    days: days,
    time: time,
  );
}

Widget buildCompactTaskCountdown(BuildContext context, TaskCountdownData data) {
  final colors = Theme.of(context).colorScheme;
  final minutes = (data.seconds / 60).ceil();
  final hours = minutes ~/ 60;
  final remaining = minutes % 60;
  final duration = hours > 0
      ? context.tr('{hours}h {minutes}m', {
          'hours': '$hours',
          'minutes': '$remaining',
        })
      : context.tr('{minutes} min', {'minutes': '$remaining'});
  final text = data.waiting
      ? context.tr('In {duration}', {'duration': duration})
      : data.running
      ? context.tr('{duration} left', {'duration': duration})
      : context.tr('Overdue');
  return Text(
    text,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: data.waiting || data.running ? colors.primary : colors.error,
    ),
  );
}
