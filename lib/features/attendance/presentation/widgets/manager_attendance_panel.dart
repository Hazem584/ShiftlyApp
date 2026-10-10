import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_cubit.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_records_list.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_rejection_dialog.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_cubit.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

class ManagerAttendancePanel extends StatelessWidget {
  const ManagerAttendancePanel({required this.timezone, super.key});
  final String timezone;

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<ManagerAttendanceCubit, ManagerAttendanceState>(
    listenWhen: (previous, current) =>
        previous.failure != current.failure && current.failure != null,
    listener: (context, state) =>
        ToastService.error(context, message: state.failure!.message),
    builder: (context, state) {
      if (state.initialLoading) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 64),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (state.records.isEmpty && state.pending.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('Recent Attendance'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            EmptyState(
              icon: state.failure == null
                  ? Icons.fact_check_outlined
                  : Icons.cloud_off_outlined,
              title: state.failure == null
                  ? 'No attendance yet'
                  : 'Could not load attendance',
              message:
                  state.failure?.message ??
                  'Employee clock-in records will appear here.',
              action: state.failure == null
                  ? null
                  : FilledButton(
                      onPressed: context.read<ManagerAttendanceCubit>().load,
                      child: Text(context.tr('Retry')),
                    ),
            ),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            key: const Key('attendance-date-employee-filters'),
            onPressed: () => _showFilters(context, state),
            icon: const Icon(Icons.tune_rounded),
            label: Text(
              state.query.from == null &&
                      state.query.employeeMembershipId == null
                  ? context.tr('Date and employee filters')
                  : context.tr('Change active filters'),
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          DropdownButtonFormField<AttendanceReviewStatus?>(
            key: const Key('attendance-review-filter'),
            initialValue: state.query.reviewStatus,
            decoration: InputDecoration(
              labelText: context.tr('Review status'),
              prefixIcon: const Icon(Icons.filter_list_rounded),
            ),
            items: [
              DropdownMenuItem(
                value: null,
                child: Text(context.tr('All records')),
              ),
              DropdownMenuItem(
                value: AttendanceReviewStatus.pending,
                child: Text(context.tr('Pending')),
              ),
              DropdownMenuItem(
                value: AttendanceReviewStatus.approved,
                child: Text(context.tr('Approved')),
              ),
              DropdownMenuItem(
                value: AttendanceReviewStatus.rejected,
                child: Text(context.tr('Rejected')),
              ),
            ],
            onChanged: (status) => context.read<ManagerAttendanceCubit>().load(
              query: AttendanceQuery(
                from: state.query.from,
                to: state.query.to,
                employeeMembershipId: state.query.employeeMembershipId,
                reviewStatus: status,
                shiftStatus: state.query.shiftStatus,
              ),
            ),
          ),
          if (state.failure != null) ...[
            const SizedBox(height: AppSpacing.s),
            Text(
              state.failure!.message,
              style: TextStyle(color: AppPalette.of(context).error),
            ),
          ],
          if (state.pending.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.l),
            AttendanceRecordsList(
              records: state.pending,
              timezone: timezone,
              title: context.tr('Pending attendance requests'),
              onTap: (record) => _details(context, record.id),
              trailing: (record) => state.reviewingIds.contains(record.id)
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right_rounded),
            ),
            if (state.hasMorePending)
              OutlinedButton(
                onPressed: state.loadingMorePending
                    ? null
                    : context.read<ManagerAttendanceCubit>().loadMorePending,
                child: Text(context.tr('Load more requests')),
              ),
          ],
          if (state.records.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.l),
            AttendanceRecordsList(
              records: state.records,
              timezone: timezone,
              onTap: (record) => _details(context, record.id),
            ),
            if (state.hasMore)
              OutlinedButton(
                onPressed: state.loadingMore
                    ? null
                    : context.read<ManagerAttendanceCubit>().loadMore,
                child: Text(context.tr('Load more attendance')),
              ),
          ],
        ],
      );
    },
  );

  List<Employee> _activeEmployees(BuildContext context) {
    final employees = context.read<EmployeesCubit>().state;
    if (employees is! EmployeesLoaded) return const [];
    return employees.employees
        .where(
          (employee) =>
              employee.employmentStatus == EmploymentStatus.active &&
              employee.role == EmployeeRole.employee,
        )
        .toList(growable: false);
  }

  Future<void> _showFilters(
    BuildContext context,
    ManagerAttendanceState state,
  ) async {
    final employees = _activeEmployees(context);
    var employeeId = state.query.employeeMembershipId;
    DateTimeRange? dates;
    if (state.query.from != null && state.query.to != null) {
      dates = DateTimeRange(
        start: WorkspaceTime.inWorkspace(state.query.from!, timezone),
        end: WorkspaceTime.inWorkspace(state.query.to!, timezone),
      );
    }
    final query = await showDialog<AttendanceQuery>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.tr('Attendance filters')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String?>(
                initialValue: employeeId,
                decoration: InputDecoration(labelText: context.tr('Employee')),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(context.tr('All employees')),
                  ),
                  for (final employee in employees)
                    DropdownMenuItem(
                      value: employee.id,
                      child: Text(employee.displayName),
                    ),
                ],
                onChanged: (value) => setDialogState(() => employeeId = value),
              ),
              const SizedBox(height: AppSpacing.m),
              OutlinedButton.icon(
                onPressed: () async {
                  final now = WorkspaceTime.inWorkspace(
                    DateTime.now().toUtc(),
                    timezone,
                  );
                  final selected = await showDateRangePicker(
                    context: dialogContext,
                    firstDate: DateTime(now.year - 3),
                    lastDate: DateTime(now.year + 3, 12, 31),
                    initialDateRange: dates,
                  );
                  if (selected != null) {
                    setDialogState(() => dates = selected);
                  }
                },
                icon: const Icon(Icons.date_range_outlined),
                label: Text(
                  dates == null
                      ? context.tr('Any date')
                      : context.tr(
                          '{value1}-{value2}-{value3} to {value4}-{value5}-{value6}',
                          {
                            'value1': (dates!.start.year).toString(),
                            'value2': (dates!.start.month).toString(),
                            'value3': (dates!.start.day).toString(),
                            'value4': (dates!.end.year).toString(),
                            'value5': (dates!.end.month).toString(),
                            'value6': (dates!.end.day).toString(),
                          },
                        ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                AttendanceQuery(reviewStatus: state.query.reviewStatus),
              ),
              child: Text(context.tr('Clear')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                AttendanceQuery(
                  employeeMembershipId: employeeId,
                  reviewStatus: state.query.reviewStatus,
                  from: dates == null
                      ? null
                      : WorkspaceTime.wallTimeToUtc(
                          date: dates!.start,
                          hour: 0,
                          minute: 0,
                          timezoneName: timezone,
                        ),
                  to: dates == null
                      ? null
                      : WorkspaceTime.wallTimeToUtc(
                          date: dates!.end,
                          hour: 23,
                          minute: 59,
                          timezoneName: timezone,
                        ),
                ),
              ),
              child: Text(context.tr('Apply')),
            ),
          ],
        ),
      ),
    );
    if (query != null && context.mounted) {
      await context.read<ManagerAttendanceCubit>().load(query: query);
    }
  }

  Future<void> _details(BuildContext context, String attendanceId) async {
    final record = await context.read<ManagerAttendanceCubit>().loadDetails(
      attendanceId,
    );
    if (record == null || !context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  record.employee.displayName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.m),
                Text(
                  record.source == AttendanceSource.template
                      ? context.tr('Template: {value1} • {value2}', {
                          'value1': (record.templateName ?? 'Unavailable')
                              .toString(),
                          'value2': (record.operationalDate ?? 'Unknown date')
                              .toString(),
                        })
                      : context.tr('Shift: {value1}', {
                          'value1':
                              (record.shift == null
                                      ? 'Unavailable'
                                      : WorkspaceTime.dateTime(
                                          record.shift!.startsAt,
                                          timezone,
                                          locale: Localizations.localeOf(
                                            context,
                                          ).toString(),
                                        ))
                                  .toString(),
                        }),
                ),
                Text(
                  context.tr('Clock-in: {value1}', {
                    'value1': (WorkspaceTime.time(
                      record.clockInAt,
                      record.workspaceTimezone ?? timezone,
                      locale: Localizations.localeOf(context).toString(),
                    )).toString(),
                  }),
                ),
                Text(
                  context.tr('Clock-out: {value1}', {
                    'value1': (WorkspaceTime.time(
                      record.clockOutAt,
                      record.workspaceTimezone ?? timezone,
                      locale: Localizations.localeOf(context).toString(),
                    )).toString(),
                  }),
                ),
                if (record.source == AttendanceSource.template) ...[
                  Text(
                    record.occurrenceKind == 'EXTRA'
                        ? context.tr(
                            'EXTRA: no baseline substitution or automatic BLUE',
                          )
                        : record.occurrenceKind == 'BASELINE'
                        ? context.tr('BASELINE attendance')
                        : context.tr(
                            'Historical template attendance; assignment evidence not recorded',
                          ),
                  ),
                  if (record.assignmentId != null)
                    Text(
                      context.tr('Assignment: {value1}', {
                        'value1': (record.assignmentId).toString(),
                      }),
                    ),
                  if (record.extraAuthorizationId != null)
                    Text(
                      context.tr('Extra authorization: {value1}', {
                        'value1': (record.extraAuthorizationId).toString(),
                      }),
                    ),
                  if (record.enteredByMembershipId != null)
                    Text(
                      context.tr('Entered by membership: {value1}', {
                        'value1': (record.enteredByMembershipId).toString(),
                      }),
                    ),
                  if (record.scheduledStartAt != null &&
                      record.scheduledEndAt != null)
                    Text(
                      context.tr('Saved schedule: {value1} to {value2}', {
                        'value1': (WorkspaceTime.dateTime(
                          record.scheduledStartAt!,
                          record.workspaceTimezone ?? timezone,
                        )).toString(),
                        'value2': (WorkspaceTime.dateTime(
                          record.scheduledEndAt!,
                          record.workspaceTimezone ?? timezone,
                        )).toString(),
                      }),
                    ),
                ],
                Text(
                  context.tr('Late: {value1} minutes', {
                    'value1': (record.minutesLate).toString(),
                  }),
                ),
                if (record.workedMinutes != null)
                  Text(
                    context.tr('Worked: {value1} minutes', {
                      'value1': (record.workedMinutes).toString(),
                    }),
                  ),
                if (record.rejectionReason != null) ...[
                  const SizedBox(height: AppSpacing.s),
                  Text(
                    context.tr('Rejection reason: {value1}', {
                      'value1': (record.rejectionReason).toString(),
                    }),
                  ),
                ],
                if (record.canReview) ...[
                  const SizedBox(height: AppSpacing.l),
                  FilledButton.icon(
                    key: const Key('approve-attendance'),
                    onPressed: () async {
                      final result = await context
                          .read<ManagerAttendanceCubit>()
                          .review(record.id, AttendanceReviewDecision.approved);
                      if (!context.mounted) return;
                      if (result == AttendanceMutationResult.success) {
                        Navigator.pop(sheetContext);
                        ToastService.success(
                          context,
                          message: 'Attendance approved.',
                        );
                      }
                    },
                    icon: const Icon(Icons.check_rounded),
                    label: Text(context.tr('Approve')),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  OutlinedButton.icon(
                    key: const Key('reject-attendance'),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _reject(context, record.id);
                    },
                    icon: const Icon(Icons.close_rounded),
                    label: Text(context.tr('Reject')),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _reject(BuildContext context, String attendanceId) async {
    final cubit = context.read<ManagerAttendanceCubit>();
    final rejected = await showDialog<bool>(
      context: context,
      builder: (_) =>
          AttendanceRejectionDialog(cubit: cubit, attendanceId: attendanceId),
    );
    if (context.mounted && rejected == true) {
      ToastService.success(context, message: 'Attendance rejected.');
    }
  }
}
