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
    final locale = Localizations.localeOf(context).toString();
    final date = task.nextDueAt(DateTime.now()).toLocal();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: busy ? null : onOpen,
        onLongPress: busy
            ? null
            : () => showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder: (c) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: Text(context.tr('Task details')),
                        onTap: () {
                          Navigator.pop(c);
                          onOpen();
                        },
                      ),
                      ListTile(
                        title: Text(context.tr('Delete task')),
                        leading: Icon(
                          Icons.delete_outline,
                          color: colors.error,
                        ),
                        onTap: () {
                          Navigator.pop(c);
                          onDelete();
                        },
                      ),
                    ],
                  ),
                ),
              ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 20, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 36,
                height: 32,
                child: Checkbox(
                  value: task.completed,
                  onChanged: busy ? null : (_) => onToggle(),
                  semanticLabel: context.tr(
                    task.completed ? 'Reopen task' : 'Complete task',
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                  side: BorderSide(color: colors.outlineVariant),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        decoration: task.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${DateFormat.MMMd(locale).format(date)} · ${DateFormat.Hm(locale).format(date)}${task.durationMinutes == null ? '' : ' · ${task.durationMinutes} ${context.tr('min')}'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    if (!task.completed)
                      TaskCountdown(task: task, compact: true)
                    else
                      Text(
                        context.tr('Completed'),
                        style: TextStyle(color: colors.primary, fontSize: 13),
                      ),
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
