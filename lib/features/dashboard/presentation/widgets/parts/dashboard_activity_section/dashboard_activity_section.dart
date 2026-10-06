part of '../../dashboard_activity_section.dart';

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
