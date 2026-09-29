import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/attendance/data/leave_request_repository.dart';
import 'package:shiftly/features/dashboard/data/dashboard_repository.dart';
import 'package:shiftly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/dashboard_loading.dart';

class EmployeeDashboardScreen extends StatelessWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) => switch (state) {
          DashboardLoading() => const DashboardLoadingView(),
          DashboardLoaded(:final data) when data is EmployeeDashboardData =>
            _EmployeeDashboard(data: data, state: state),
          DashboardLoaded() => const SizedBox.shrink(),
          DashboardError(:final failure) => EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load your overview',
            message: failure.message,
            action: FilledButton.icon(
              onPressed: context.read<DashboardCubit>().load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ),
        },
      );
}

class _EmployeeDashboard extends StatelessWidget {
  const _EmployeeDashboard({required this.data, required this.state});
  final EmployeeDashboardData data;
  final DashboardLoaded state;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () => context.read<DashboardCubit>().load(refresh: true),
    child: ListView(
      key: const Key('employee-dashboard-content'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        Text(
          'Hello, ${data.employee.fullName}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          '${data.date} · ${data.timezone}',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        if (state.failure != null) ...[
          const SizedBox(height: AppSpacing.s),
          Text(
            state.failure!.message,
            style: const TextStyle(color: AppColors.error, fontSize: 12),
          ),
        ],
        const SizedBox(height: AppSpacing.m),
        _ShiftCard(
          title: "Today's shift",
          shift: data.todayShift,
          timezone: data.timezone,
          attendance: data.attendance,
        ),
        const SizedBox(height: AppSpacing.m),
        _ShiftCard(
          title: 'Next shift',
          shift: data.nextShift,
          timezone: data.timezone,
        ),
        const SizedBox(height: AppSpacing.m),
        Row(
          children: [
            Expanded(
              child: _CountCard(
                label: 'Pending leave',
                value: data.summary.pendingLeaveRequests,
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: _CountCard(
                label: 'Upcoming approved',
                value: data.summary.approvedLeaveRequests,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.l),
        Text(
          'Recent leave requests',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.s),
        SurfaceCard(
          padding: data.recentLeaveRequests.isEmpty
              ? const EdgeInsets.all(16)
              : EdgeInsets.zero,
          child: data.recentLeaveRequests.isEmpty
              ? const Text(
                  'No leave requests yet.',
                  style: TextStyle(color: AppColors.textSecondary),
                )
              : Column(
                  children: [
                    for (final request in data.recentLeaveRequests)
                      ListTile(
                        key: Key('employee-dashboard-leave-${request.id}'),
                        title: Text(_leaveType(request.type)),
                        subtitle: Text(
                          '${WorkspaceTime.dateTime(request.startsAt, data.timezone)}\n'
                          '${request.reason}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(_leaveStatus(request.status)),
                      ),
                  ],
                ),
        ),
      ],
    ),
  );
}

class _ShiftCard extends StatelessWidget {
  const _ShiftCard({
    required this.title,
    required this.shift,
    required this.timezone,
    this.attendance,
  });
  final String title;
  final EmployeeDashboardShift? shift;
  final String timezone;
  final DashboardAttendance? attendance;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.s),
      SurfaceCard(
        child: shift == null
            ? const Text(
                'No shift scheduled.',
                style: TextStyle(color: AppColors.textSecondary),
              )
            : Row(
                children: [
                  const Icon(Icons.schedule_rounded, color: AppColors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${WorkspaceTime.time(shift!.startsAt, timezone)} – '
                      '${WorkspaceTime.time(shift!.endsAt, timezone)}',
                      maxLines: 2,
                    ),
                  ),
                  if (attendance != null)
                    Text(
                      attendance!.status == DashboardAttendanceStatus.completed
                          ? 'Completed'
                          : 'Clocked in',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                ],
              ),
      ),
    ],
  );
}

class _CountCard extends StatelessWidget {
  const _CountCard({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '$value',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
      ],
    ),
  );
}

String _leaveType(LeaveRequestType type) => switch (type) {
  LeaveRequestType.annualLeave => 'Annual leave',
  LeaveRequestType.sickLeave => 'Sick leave',
  LeaveRequestType.emergencyLeave => 'Emergency leave',
  LeaveRequestType.earlyLeave => 'Early leave',
  LeaveRequestType.other => 'Other leave',
  LeaveRequestType.unknown => 'Leave request',
};

String _leaveStatus(LeaveRequestStatus status) => switch (status) {
  LeaveRequestStatus.pending => 'Pending',
  LeaveRequestStatus.approved => 'Approved',
  LeaveRequestStatus.rejected => 'Rejected',
  LeaveRequestStatus.cancelled => 'Cancelled',
  LeaveRequestStatus.unknown => 'Updated',
};
