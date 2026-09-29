import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/routing/app_routes.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/dashboard/data/dashboard_repository.dart';

class DashboardActivitySection extends StatelessWidget {
  const DashboardActivitySection({
    required this.shifts,
    required this.timezone,
    super.key,
  });

  final List<DashboardShiftPreview> shifts;
  final String timezone;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text("Today's shifts", style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.s),
      SurfaceCard(
        padding: shifts.isEmpty ? const EdgeInsets.all(16) : EdgeInsets.zero,
        child: shifts.isEmpty
            ? const Text(
                'No shifts are scheduled for this workspace day.',
                style: TextStyle(color: AppColors.textSecondary),
              )
            : Column(
                children: [
                  for (var index = 0; index < shifts.length; index++) ...[
                    _ShiftTile(shift: shifts[index], timezone: timezone),
                    if (index < shifts.length - 1)
                      const Divider(height: 1, indent: 64, endIndent: 14),
                  ],
                ],
              ),
      ),
    ],
  );
}

class DashboardApprovalsCard extends StatelessWidget {
  const DashboardApprovalsCard({required this.pendingRequests, super.key});
  final int pendingRequests;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Pending leave', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.s),
      SurfaceCard(
        child: Row(
          children: [
            const Icon(
              Icons.pending_actions_outlined,
              color: AppColors.warning,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                '$pendingRequests leave requests waiting',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              onPressed: () => context.go(AppRoutes.attendanceLeaveRequests),
              tooltip: 'Review leave requests',
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ],
        ),
      ),
    ],
  );
}

class _ShiftTile extends StatelessWidget {
  const _ShiftTile({required this.shift, required this.timezone});
  final DashboardShiftPreview shift;
  final String timezone;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    leading: CircleAvatar(
      backgroundColor: AppColors.field,
      foregroundColor: AppColors.ink,
      child: Text(shift.employee.fullName.characters.first.toUpperCase()),
    ),
    title: Text(
      shift.employee.fullName,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    subtitle: Text(
      '${WorkspaceTime.time(shift.startsAt, timezone)} – '
      '${WorkspaceTime.time(shift.endsAt, timezone)}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
    trailing: Text(
      _attendanceLabel(shift.attendance),
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

String _attendanceLabel(DashboardAttendance? attendance) =>
    switch (attendance?.status) {
      DashboardAttendanceStatus.clockedIn => 'Clocked in',
      DashboardAttendanceStatus.completed => 'Completed',
      DashboardAttendanceStatus.unknown => 'Recorded',
      null => 'Scheduled',
    };
