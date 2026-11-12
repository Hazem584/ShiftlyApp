import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/features/attendance/presentation/cubit/attendance_calendar_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/employee_attendance_calendar_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';

import 'employee_attendance_gate.dart';
import 'employee_scheduled_shift_screen.dart';
import 'employee_shift_details_screen.dart';
import 'employee_tile.dart';

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
    _week =
        (WorkspaceTime.inWorkspace(
              widget.now?.call() ?? DateTime.now(),
              widget.timezone,
            ).day -
            1) ~/
        7;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<EmployeeAttendanceCalendarCubit>().open();
    });
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<EmployeeAttendanceCalendarCubit, AttendanceCalendarState>(
    builder: (context, calendar) => BlocBuilder<FlexibleAttendanceCubit, FlexibleAttendanceState>(
      builder: (context, state) {
        final data = calendar.data;
        final allEntries = state.eligibility?.authorizedOccurrences ?? const [];
        final shifts = [...?data?.scheduledShifts]
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
        final locale = Localizations.localeOf(context).toString();
        final month = DateTime(
          calendar.year ?? DateTime.now().year,
          calendar.month ?? DateTime.now().month,
        );
        final c = context.read<EmployeeAttendanceCalendarCubit>();
        final firstDay = (_week * 7 + 1).clamp(
          1,
          DateTime(month.year, month.month + 1, 0).day,
        );
        final lastDay = (firstDay + 6).clamp(
          1,
          DateTime(month.year, month.month + 1, 0).day,
        );
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
              (s) =>
                  visible(WorkspaceTime.dateKey(s.startsAt, widget.timezone)),
            )
            .toList();

        return RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              c.load(refresh: true),
              context.read<FlexibleAttendanceCubit>().load(refresh: true),
            ]);
          },
          child: ListView(
            key: const Key('employee-schedule'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '$firstDay–$lastDay ${DateFormat.yMMMM(locale).format(month)} · ${widget.timezone}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: context.tr('Previous week'),
                    onPressed: calendar.loading || calendar.refreshing
                        ? null
                        : () => _move(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  IconButton(
                    tooltip: context.tr('Next week'),
                    onPressed: calendar.loading || calendar.refreshing
                        ? null
                        : () => _move(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (state.recovery != null ||
                  state.recoveryBlocked ||
                  state.legacyReviewRequired ||
                  (entries.isEmpty && allEntries.isEmpty)) ...[
                EmployeeAttendanceGate(state: state, timezone: widget.timezone),
                const SizedBox(height: 16),
              ],
              if (calendar.loading && data == null) const AppContentLoading(),
              if (calendar.failure != null) ...[
                Text(
                  calendar.failure!.message,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                TextButton(
                  onPressed: () => c.load(refresh: true),
                  child: Text(context.tr('Retry')),
                ),
              ],
              for (final e in entries.where(
                (e) =>
                    DateTime.parse(e.operationalDate).month == month.month &&
                    DateTime.parse(e.operationalDate).year == month.year,
              )) ...[
                EmployeeTile(
                  key: Key('schedule-occurrence-${e.identity}'),
                  title:
                      '${DateFormat.MMMEd(locale).format(DateTime.parse(e.operationalDate))} · ${e.template.name}',
                  subtitle:
                      '${WorkspaceTime.time(e.scheduledStartAt, widget.timezone, locale: locale)}–${WorkspaceTime.time(e.scheduledEndAt, widget.timezone, locale: locale)} · ${context.tr(e.alreadyUsed
                          ? 'Recorded'
                          : e.scheduleExceptionId != null
                          ? 'Date-specific change'
                          : e.occurrenceKind == 'EXTRA'
                          ? 'Authorized extra'
                          : 'Baseline assignment')}',
                  icon: e.occurrenceKind == 'EXTRA'
                      ? Icons.add
                      : Icons.calendar_today_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => EmployeeShiftDetailsScreen(
                        entry: e,
                        timezone: widget.timezone,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              for (final shift in visibleShifts.where(
                (s) => !entries.any(
                  (e) =>
                      e.operationalDate ==
                          WorkspaceTime.dateKey(s.startsAt, widget.timezone) &&
                      ((e.assignmentId != null &&
                              e.assignmentId == s.assignmentId) ||
                          (e.extraAuthorizationId != null &&
                              e.extraAuthorizationId ==
                                  s.extraAuthorizationId)),
                ),
              )) ...[
                EmployeeTile(
                  title:
                      '${DateFormat.MMMEd(locale).format(WorkspaceTime.inWorkspace(shift.startsAt, widget.timezone))} · ${shift.notes?.trim().isNotEmpty == true ? shift.notes : context.tr('Scheduled shift')}',
                  subtitle:
                      '${WorkspaceTime.time(shift.startsAt, widget.timezone, locale: locale)}–${WorkspaceTime.time(shift.endsAt, widget.timezone, locale: locale)} · ${context.tr(shift.extraAuthorizationId != null ? 'Authorized extra' : 'Baseline assignment')}',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => EmployeeScheduledShiftScreen(
                        shift: shift,
                        timezone: widget.timezone,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
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
