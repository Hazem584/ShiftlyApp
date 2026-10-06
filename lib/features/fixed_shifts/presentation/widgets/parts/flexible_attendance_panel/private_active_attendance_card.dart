part of '../../flexible_attendance_panel.dart';

class _ActiveAttendanceCard extends StatelessWidget {
  const _ActiveAttendanceCard({
    required this.attendance,
    required this.timezone,
    required this.busy,
    required this.onClockOut,
  });
  final FlexibleAttendance attendance;
  final String timezone;
  final bool busy;
  final VoidCallback onClockOut;
  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 48,
              decoration: BoxDecoration(
                color: _color(attendance.templateColor ?? '#334155'),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active attendance',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    attendance.templateName ?? 'Fixed shift',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const Icon(Icons.radio_button_checked, color: AppColors.success),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Clocked in: ${WorkspaceTime.dateTime(attendance.clockInAt, attendance.workspaceTimezone ?? timezone)}',
        ),
        if (attendance.scheduledStartAt != null &&
            attendance.scheduledEndAt != null)
          Text(
            'Schedule: ${WorkspaceTime.time(attendance.scheduledStartAt, timezone)} – ${WorkspaceTime.time(attendance.scheduledEndAt, timezone)}',
          ),
        Text(
          'Operational date: ${attendance.operationalDate ?? 'Unavailable'}',
        ),
        Text(
          '${_classification(attendance.classification ?? AttendanceClassification.unknown)}${attendance.minutesLate > 0 ? ' • ${attendance.minutesLate} min late' : ''}',
        ),
        const SizedBox(height: 6),
        StreamBuilder<int>(
          stream: Stream<int>.periodic(
            const Duration(minutes: 1),
            (value) => value,
          ),
          builder: (_, _) => Text(
            'Elapsed (display only): ${_elapsed(DateTime.now().toUtc().difference(attendance.clockInAt))}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: busy ? null : onClockOut,
            icon: busy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded),
            label: const Text('Clock out'),
          ),
        ),
      ],
    ),
  );
}
