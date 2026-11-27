import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/work_pattern.dart';
import 'package:shiftly/features/fixed_shifts/presentation/utils/saved_schedule_formatter.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/weekday_row.dart';

class WorkPatternHistoryTile extends StatelessWidget {
  const WorkPatternHistoryTile({
    required this.pattern,
    required this.isCurrent,
    required this.timezone,
    super.key,
  });
  final WorkPattern pattern;
  final bool isCurrent;
  final String timezone;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(
      pattern.effectiveTo == null
          ? Icons.event_available_outlined
          : Icons.history_rounded,
    ),
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isCurrent
              ? context.tr('Current assignment')
              : pattern.effectiveFrom.compareTo(
                      WorkspaceTime.dateKey(DateTime.now().toUtc(), timezone),
                    ) >
                    0
              ? context.tr('Future assignment')
              : context.tr('Historical assignment'),
        ),
        WeekdayRow(days: pattern.expectedWeekdays),
      ],
    ),
    subtitle: Text(
      context.tr('{value1}\n{value2} → {value3}', {
        'value1': pattern.assignmentSnapshot != null
            ? savedScheduleLabel(context, pattern.assignmentSnapshot!)
            : context.tr('Assignment evidence not recorded'),
        'value2': pattern.effectiveFrom,
        'value3': pattern.effectiveTo ?? context.tr('ongoing'),
      }),
    ),
  );
}
