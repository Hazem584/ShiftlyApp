part of '../../employee_dashboard_screen.dart';

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
        const PerformanceThumbnail(),
        const SizedBox(height: AppSpacing.m),
        Card(
          child: ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Fixed shifts'),
            subtitle: const Text(
              'View available templates and clock in or out',
            ),
            onTap: () => context.go('/employee?tab=shifts'),
          ),
        ),
        if (data.todayShift != null)
          _ShiftCard(
            title: 'Legacy scheduled shift',
            shift: data.todayShift,
            timezone: data.timezone,
            attendance: data.attendance,
          ),
        const SizedBox(height: AppSpacing.m),
        if (data.nextShift != null)
          _ShiftCard(
            title: 'Next legacy scheduled shift',
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
                          '${WorkspaceTime.dateTime(request.startsAt, data.timezone, locale: Localizations.localeOf(context).toString())}\n'
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
