part of '../../employee_dashboard_screen.dart';

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
                    Text(switch (attendance!.status) {
                      DashboardAttendanceStatus.clockedIn => 'Clocked in',
                      DashboardAttendanceStatus.completed => 'Completed',
                      DashboardAttendanceStatus.unknown => 'Recorded',
                    }, style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
      ),
    ],
  );
}
