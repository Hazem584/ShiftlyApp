import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/features/attendance/presentation/cubit/attendance_calendar_cubit.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_calendar_grid.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_calendar_legend.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_calendar_month_header.dart';

class AttendanceCalendarMonthCard extends StatelessWidget {
  const AttendanceCalendarMonthCard({required this.state, super.key});
  final AttendanceCalendarState state;

  @override
  Widget build(BuildContext context) {
    final data = state.data!;
    return Card(
      key: const Key('attendance-calendar-card'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('Attendance Calendar'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.m),
            AttendanceCalendarMonthHeader(
              year: data.year,
              month: data.month,
              onPrevious: context.read<AttendanceCalendarCubit>().previousMonth,
              onNext: context.read<AttendanceCalendarCubit>().nextMonth,
            ),
            const SizedBox(height: AppSpacing.s),
            AttendanceCalendarGrid(
              data: data,
              selectedDate: state.selectedDate,
              onSelected: context.read<AttendanceCalendarCubit>().selectDate,
            ),
            const SizedBox(height: AppSpacing.m),
            const AttendanceCalendarLegend(),
            if (state.refreshing) ...[
              const SizedBox(height: AppSpacing.s),
              const AppContentLoading(key: Key('calendar-refreshing'), rows: 1),
            ],
          ],
        ),
      ),
    );
  }
}
