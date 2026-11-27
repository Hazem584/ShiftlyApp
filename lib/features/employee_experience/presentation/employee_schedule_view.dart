import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/features/attendance/presentation/cubit/attendance_calendar_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_attendance_calendar_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';

import 'employee_attendance_gate.dart';
import 'employee_schedule_tiles.dart';
import 'employee_schedule_week_header.dart';

class EmployeeScheduleView extends StatefulWidget {
  const EmployeeScheduleView({required this.timezone, this.now, super.key});
  final String timezone;
  final DateTime Function()? now;
  @override
  State<EmployeeScheduleView> createState() => _EmployeeScheduleViewState();
}

class _EmployeeScheduleViewState extends State<EmployeeScheduleView> {
  late int _week;
  Future<void> _move(int delta) async {
    final c = context.read<EmployeeAttendanceCalendarCubit>();
    final year = c.state.year ?? DateTime.now().year,
        month = c.state.month ?? DateTime.now().month;
    final count = (DateTime(year, month + 1, 0).day / 7).ceil();
    final next = _week + delta;
    if (next < 0) {
      setState(() => _week = (DateTime(year, month, 0).day - 1) ~/ 7);
      await c.previousMonth();
    } else if (next >= count) {
      setState(() => _week = 0);
      await c.nextMonth();
    } else {
      setState(() => _week = next);
    }
  }

  @override
  void initState() {
    super.initState();
    final current = WorkspaceTime.inWorkspace(
      widget.now?.call() ?? DateTime.now(),
      widget.timezone,
    );
    _week = (current.day - 1) ~/ 7;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<EmployeeAttendanceCalendarCubit>().open();
    });
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<EmployeeAttendanceCalendarCubit, AttendanceCalendarState>(
        builder: (context, calendar) =>
            BlocBuilder<FlexibleAttendanceCubit, FlexibleAttendanceState>(
              builder: (context, state) {
                final data = calendar.data;
                final allEntries =
                    state.eligibility?.authorizedOccurrences ?? const [];
                final shifts = [...?data?.scheduledShifts]
                  ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
                final locale = Localizations.localeOf(context).toString();
                final month = DateTime(
                  calendar.year ?? DateTime.now().year,
                  calendar.month ?? DateTime.now().month,
                );
                final maxDay = DateTime(month.year, month.month + 1, 0).day;
                final firstDay = (_week * 7 + 1).clamp(1, maxDay);
                final lastDay = (firstDay + 6).clamp(1, maxDay);
                bool visible(String date) {
                  final d = DateTime.parse(date);
                  return d.year == month.year &&
                      d.month == month.month &&
                      d.day >= firstDay &&
                      d.day <= lastDay;
                }

                final entries = allEntries
                    .where((e) => visible(e.operationalDate))
                    .toList();
                final visibleShifts = shifts
                    .where(
                      (s) => visible(
                        WorkspaceTime.dateKey(s.startsAt, widget.timezone),
                      ),
                    )
                    .toList();
                final c = context.read<EmployeeAttendanceCalendarCubit>();
                return RefreshIndicator(
                  onRefresh: () => Future.wait([
                    c.load(refresh: true),
                    context.read<FlexibleAttendanceCubit>().load(refresh: true),
                  ]),
                  child: ListView(
                    key: const Key('employee-schedule'),
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      EmployeeScheduleWeekHeader(
                        firstDay: firstDay,
                        lastDay: lastDay,
                        month: month,
                        timezone: widget.timezone,
                        busy: calendar.loading || calendar.refreshing,
                        onMove: _move,
                      ),
                      const SizedBox(height: 20),
                      if (state.recovery != null ||
                          state.recoveryBlocked ||
                          state.legacyReviewRequired ||
                          (entries.isEmpty && allEntries.isEmpty)) ...[
                        EmployeeAttendanceGate(
                          state: state,
                          timezone: widget.timezone,
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (calendar.loading && data == null)
                        const AppContentLoading(),
                      if (calendar.failure != null) ...[
                        Text(
                          calendar.failure!.message,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        TextButton(
                          onPressed: () => c.load(refresh: true),
                          child: Text(context.tr('Retry')),
                        ),
                      ],
                      ...buildScheduleOccurrenceTiles(
                        context: context,
                        entries: entries,
                        month: month,
                        locale: locale,
                        timezone: widget.timezone,
                      ),
                      ...buildScheduledShiftTiles(
                        context: context,
                        visibleShifts: visibleShifts,
                        entries: entries,
                        locale: locale,
                        timezone: widget.timezone,
                      ),
                      if (!calendar.loading &&
                          data != null &&
                          visibleShifts.isEmpty &&
                          entries.isEmpty)
                        Text(context.tr('No scheduled shifts in this week.')),
                    ],
                  ),
                );
              },
            ),
      );
}
