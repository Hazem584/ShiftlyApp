part of '../../dashboard_activity_section.dart';

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
