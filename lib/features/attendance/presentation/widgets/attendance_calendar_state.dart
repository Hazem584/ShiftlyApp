import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/features/attendance/presentation/cubit/attendance_calendar_cubit.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_calendar_selected_day.dart';

import 'attendance_calendar_month_card.dart';
import 'attendance_month_controls.dart';

class AttendanceCalendarStateView extends StatelessWidget {
  const AttendanceCalendarStateView({this.editable = false, super.key});
  final bool editable;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AttendanceCalendarCubit, AttendanceCalendarState>(
        builder: (context, state) {
          if (state.loading && !state.hasData) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: AppContentLoading(),
            );
          }
          if (state.failure != null && !state.hasData) {
            return EmptyState(
              icon: Icons.calendar_month_outlined,
              title: context.tr('Could not load calendar'),
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
              AttendanceCalendarMonthCard(state: state),
              if (state.failure != null && state.hasData) ...[
                const SizedBox(height: AppSpacing.s),
                Text(
                  state.failure!.message,
                  key: const Key('calendar-refresh-error'),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: AppSpacing.m),
              AttendanceMonthControls(month: data),
              AttendanceCalendarSelectedDay(
                closed: data.control?.closed ?? false,
                editable: editable,
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
