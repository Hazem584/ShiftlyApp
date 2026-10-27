import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class TaskProgressOverview extends StatelessWidget {
  const TaskProgressOverview({
    required this.open,
    required this.done,
    super.key,
  });
  final int? open, done;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final available = open != null && done != null;
    final total = (open ?? 0) + (done ?? 0);
    final progress = total == 0 ? 0.0 : (done ?? 0) / total;
    return Container(
      key: const Key('task-progress-overview'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('Your progress'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                available ? '${(progress * 100).round()}%' : '—',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: available ? progress : 0,
            minHeight: 6,
            borderRadius: BorderRadius.circular(8),
            semanticsLabel: context.tr('Task completion progress'),
          ),
          const SizedBox(height: 10),
          Text(
            available
                ? context.tr('{done} done · {open} remaining', {
                    'done': '$done',
                    'open': '$open',
                  })
                : context.tr('Task totals are unavailable. Refresh to retry.'),
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
