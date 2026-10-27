import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import '../../domain/personal_task.dart';
import 'task_countdown.dart';

class TaskCard extends StatelessWidget {
  const TaskCard({
    required this.task,
    required this.busy,
    required this.onOpen,
    required this.onToggle,
    required this.onDelete,
    super.key,
  });
  final PersonalTask task;
  final bool busy;
  final VoidCallback onOpen, onToggle, onDelete;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = task.completed
        ? colors.primary
        : task.overdue
        ? colors.error
        : colors.tertiary;
    final locale = Localizations.localeOf(context).languageCode;
    final date = DateFormat.yMMMd(locale)
        .add_jm()
        .format(task.nextDueAt(DateTime.now()).toLocal());
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: busy ? null : onOpen,
        child: Container(
          decoration: BoxDecoration(
            border: BorderDirectional(
              start: BorderSide(color: color, width: 3),
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: task.completed,
                    onChanged: busy ? null : (_) => onToggle(),
                    semanticLabel: context.tr(
                      task.completed ? 'Reopen task' : 'Complete task',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              decoration: task.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    enabled: !busy,
                    tooltip: context.tr('Task actions'),
                    onSelected: (value) =>
                        value == 'delete' ? onDelete() : onOpen(),
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(context.tr('Edit task')),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(context.tr('Delete task')),
                      ),
                    ],
                  ),
                ],
              ),
              if (task.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 8,
                    top: 6,
                    bottom: 8,
                  ),
                  child: Text(
                    task.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              TaskCountdown(task: task),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(
                    task.completed ? Icons.task_alt : Icons.schedule_rounded,
                    size: 17,
                    color: color,
                  ),
                  Text(
                    date,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (task.durationMinutes != null)
                    Text(
                      context.tr('{minutes} min', {
                        'minutes': '${task.durationMinutes}',
                      }),
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  if (task.additionalDueAts.isNotEmpty)
                    Text(
                      context.tr('{count} alarm times', {
                        'count': '${task.scheduledDates.length}',
                      }),
                      style: TextStyle(color: colors.primary, fontSize: 12),
                    ),
                  if (task.overdue)
                    Text(
                      context.tr('Overdue'),
                      style: TextStyle(color: color, fontSize: 12),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
