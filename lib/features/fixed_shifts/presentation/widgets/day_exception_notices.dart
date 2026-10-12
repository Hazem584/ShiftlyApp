import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/schedule_exception.dart';

class DayExceptionNotices extends StatelessWidget {
  const DayExceptionNotices({super.key, required this.notices});
  final List<ScheduleExceptionNotice> notices;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final notice in notices.where((e) => e.kind != 'SHIFT'))
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${notice.operationalDate} · ${context.tr(notice.kind == 'HOLIDAY' ? 'Workspace holiday' : 'Employee day off')}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  context.tr(
                    'No baseline attendance is required for this date.',
                  ),
                ),
                Text(notice.reason),
              ],
            ),
          ),
        ),
    ],
  );
}
