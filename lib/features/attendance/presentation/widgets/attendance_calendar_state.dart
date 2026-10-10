import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/features/attendance/presentation/cubit/attendance_calendar_cubit.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_calendar_grid.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_calendar_legend.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_calendar_month_header.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_calendar_selected_day.dart';

class AttendanceCalendarStateView extends StatelessWidget {
  const AttendanceCalendarStateView({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AttendanceCalendarCubit, AttendanceCalendarState>(
        builder: (context, state) {
          if (state.loading && !state.hasData) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (state.failure != null && !state.hasData) {
            return EmptyState(
              icon: Icons.calendar_month_outlined,
              title: 'Could not load calendar',
              message: state.failure!.message,
              action: FilledButton(
                key: const Key('calendar-retry'),
                onPressed: context.read<AttendanceCalendarCubit>().load,
                child: Text(context.tr('Try again')),
              ),
            );
          }
          final data = state.data;
          if (data == null) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                key: const Key('attendance-calendar-card'),
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Attendance Calendar',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.m),
                      AttendanceCalendarMonthHeader(
                        year: data.year,
                        month: data.month,
                        onPrevious: context
                            .read<AttendanceCalendarCubit>()
                            .previousMonth,
                        onNext: context
                            .read<AttendanceCalendarCubit>()
                            .nextMonth,
                      ),
                      const SizedBox(height: AppSpacing.s),
                      AttendanceCalendarGrid(
                        data: data,
                        selectedDate: state.selectedDate,
                        onSelected: context
                            .read<AttendanceCalendarCubit>()
                            .selectDate,
                      ),
                      const SizedBox(height: AppSpacing.m),
                      const AttendanceCalendarLegend(),
                      if (state.refreshing) ...[
                        const SizedBox(height: AppSpacing.s),
                        const LinearProgressIndicator(
                          key: Key('calendar-refreshing'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (state.failure != null && state.hasData) ...[
                const SizedBox(height: AppSpacing.s),
                Text(
                  state.failure!.message,
                  key: const Key('calendar-refresh-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.m),
              AttendanceCalendarSelectedDay(
                date: state.selectedDate,
                timezone: data.timezone,
                entries: state.selectedDate == null
                    ? const []
                    : data.entriesFor(state.selectedDate!),
              ),
            ],
          );
        },
      );
}
