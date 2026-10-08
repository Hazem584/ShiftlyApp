import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/features/attendance/data/attendance_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_cubit.dart';
import 'package:shiftly/features/fixed_shifts/data/fixed_shift_repository.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_records_list.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_rejection_dialog.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_cubit.dart';
import 'package:shiftly/features/shifts/data/shift_repository.dart';

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
              'Recent Attendance',
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
                      child: const Text('Retry'),
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
                  ? 'Date and employee filters'
                  : 'Change active filters',
            ),
          ),
          const SizedBox(height: AppSpacing.s),
          DropdownButtonFormField<AttendanceReviewStatus?>(
            key: const Key('attendance-review-filter'),
            initialValue: state.query.reviewStatus,
            decoration: const InputDecoration(
              labelText: 'Review status',
              prefixIcon: Icon(Icons.filter_list_rounded),
            ),
            items: const [
              DropdownMenuItem(value: null, child: Text('All records')),
              DropdownMenuItem(
                value: AttendanceReviewStatus.pending,
                child: Text('Pending'),
              ),
              DropdownMenuItem(
                value: AttendanceReviewStatus.approved,
                child: Text('Approved'),
              ),
              DropdownMenuItem(
                value: AttendanceReviewStatus.rejected,
                child: Text('Rejected'),
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
              style: const TextStyle(color: AppColors.error),
            ),
          ],
          if (state.pending.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.l),
            AttendanceRecordsList(
              records: state.pending,
              timezone: timezone,
              title: 'Pending attendance requests',
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
                child: const Text('Load more requests'),
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
                child: const Text('Load more attendance'),
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
          title: const Text('Attendance filters'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String?>(
                initialValue: employeeId,
                decoration: const InputDecoration(labelText: 'Employee'),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All employees'),
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
                      ? 'Any date'
                      : '${dates!.start.year}-${dates!.start.month}-${dates!.start.day} '
                            'to ${dates!.end.year}-${dates!.end.month}-${dates!.end.day}',
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
              child: const Text('Clear'),
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
              child: const Text('Apply'),
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
                    ? 'Template: ${record.templateName ?? 'Unavailable'} • ${record.operationalDate ?? 'Unknown date'}'
                    : 'Shift: ${record.shift == null ? 'Unavailable' : WorkspaceTime.dateTime(record.shift!.startsAt, timezone)}',
              ),
              Text(
                'Clock-in: ${WorkspaceTime.time(record.clockInAt, timezone)}',
              ),
              Text(
                'Clock-out: ${WorkspaceTime.time(record.clockOutAt, timezone)}',
              ),
              Text('Late: ${record.minutesLate} minutes'),
              if (record.workedMinutes != null)
                Text('Worked: ${record.workedMinutes} minutes'),
              if (record.rejectionReason != null) ...[
                const SizedBox(height: AppSpacing.s),
                Text('Rejection reason: ${record.rejectionReason}'),
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
                  label: const Text('Approve'),
                ),
                const SizedBox(height: AppSpacing.s),
                OutlinedButton.icon(
                  key: const Key('reject-attendance'),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _reject(context, record.id);
                  },
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Reject'),
                ),
              ],
            ],
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
