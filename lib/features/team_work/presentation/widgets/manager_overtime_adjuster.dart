import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/work_duration.dart';

class ManagerOvertimeAdjuster extends StatelessWidget {
  const ManagerOvertimeAdjuster({
    super.key,
    required this.start,
    required this.end,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.busy,
    required this.onEndChanged,
  });

  final DateTime start, end;
  final DateTime? scheduledStart, scheduledEnd;
  final bool busy;
  final ValueChanged<DateTime> onEndChanged;

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    final workedMin = end.difference(start).inMinutes.clamp(0, 1440);
    final baseEnd = scheduledEnd ?? start.add(const Duration(hours: 8));
    final lateMs = scheduledStart != null && start.isAfter(scheduledStart!)
        ? start.difference(scheduledStart!).inMilliseconds
        : 0;
    final otMin = ((end.difference(baseEnd).inMilliseconds - lateMs) / 60000)
        .floor()
        .clamp(0, 1440);
    void shiftEnd(int deltaMinutes) {
      final candidate = end.add(Duration(minutes: deltaMinutes));
      if (candidate.isAfter(start)) onEndChanged(candidate);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          '${context.tr('Worked hours')}: ${workDuration(workedMin, arabic: ar)} · '
          '${context.tr('Overtime')}: ${workDuration(otMin, arabic: ar)}',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final (label, delta) in const [
              ('-30m', -30),
              ('-15m', -15),
              ('+15m', 15),
              ('+30m', 30),
              ('+1h', 60),
            ])
              ActionChip(
                label: Text(label),
                onPressed: busy ? null : () => shiftEnd(delta),
              ),
            if (scheduledEnd != null)
              ActionChip(
                label: Text(context.tr('Reset overtime')),
                onPressed: busy
                    ? null
                    : () {
                        final target = scheduledEnd!.add(
                          Duration(milliseconds: lateMs),
                        );
                        if (target.isAfter(start)) onEndChanged(target);
                      },
              ),
          ],
        ),
      ],
    );
  }
}
