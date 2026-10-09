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
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.ink, AppColors.inkMuted],
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
            ),
            borderRadius: BorderRadius.circular(AppRadii.xl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.wb_sunny_outlined,
                color: AppColors.selected,
                size: 28,
              ),
              const SizedBox(height: 12),
              Text(
                'Ready for your workday?',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 6),
              const Text(
                'Your shifts, attendance and time off are a tap away.',
                style: TextStyle(color: Color(0xFFE4DED6), height: 1.5),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    key: const Key('employee-quick-shifts'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.orange,
                    ),
                    onPressed: () => context.go('/employee?tab=shifts'),
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: const Text('My Shifts'),
                  ),
                  OutlinedButton.icon(
                    key: const Key('employee-quick-leave'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF8E8E9C)),
                    ),
                    onPressed: () => context.go('/employee?tab=leave'),
                    icon: const Icon(Icons.event_note_outlined),
                    label: const Text('Request leave'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        const PerformanceThumbnail(),
        const SizedBox(height: AppSpacing.m),
        SurfaceCard(
          onTap: () => context.go('/employee?tab=shifts'),
          child: const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.schedule, color: AppColors.orange),
            title: Text('Fixed shifts'),
            subtitle: Text('View available templates and clock in or out'),
            trailing: Icon(Icons.chevron_right_rounded),
          ),
        ),
        if (data.todayShift != null)
          _ShiftCard(
            title: 'Scheduled shift',
            shift: data.todayShift,
            timezone: data.timezone,
            attendance: data.attendance,
          ),
        const SizedBox(height: AppSpacing.m),
        if (data.nextShift != null)
          _ShiftCard(
            title: 'Next scheduled shift',
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
