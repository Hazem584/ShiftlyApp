import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/attendance/domain/entities/calendar_attendance_status.dart';
import 'package:shiftly/features/attendance/presentation/cubit/attendance_calendar_cubit.dart';

class AttendanceMonthSummary extends StatelessWidget {
  const AttendanceMonthSummary({super.key});
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<AttendanceCalendarCubit, AttendanceCalendarState>(
    builder: (context, state) {
      if (!state.hasData) return const SizedBox.shrink();
      final days = state.data!.days.values;
      int count(Set<CalendarAttendanceStatus> statuses) => days
          .where(
            (entries) =>
                entries.any((entry) => statuses.contains(entry.status)),
          )
          .length;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('Monthly attendance summary'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  for (final (label, value) in [
                    (
                      'Present days (including late)',
                      count({
                        CalendarAttendanceStatus.present,
                        CalendarAttendanceStatus.late,
                      }),
                    ),
                    ('Absent days', count({CalendarAttendanceStatus.absent})),
                    ('Late days', count({CalendarAttendanceStatus.late})),
                    ('Leave days', count({CalendarAttendanceStatus.leave})),
                  ])
                    Text('${context.tr(label)}  $value'),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('Friday is off unless you have an assigned shift.'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      );
    },
  );
}
