part of '../../employee_attendance_screen.dart';

class _EmployeeAttendanceScreenState extends State<EmployeeAttendanceScreen> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    final timezone =
        context
            .watch<SessionCoordinator>()
            .state
            .activeMembership
            ?.workspace
            .timezone ??
        'Etc/UTC';
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ScreenHeader(
                  title: 'Attendance & Leave',
                  subtitle: 'Your workspace attendance and leave requests',
                ),
                const SizedBox(height: AppSpacing.m),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(
                      value: 0,
                      icon: Icon(Icons.history_rounded),
                      label: Text('Attendance'),
                    ),
                    ButtonSegment(
                      value: 1,
                      icon: Icon(Icons.event_note_outlined),
                      label: Text('Leave'),
                    ),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (selected) =>
                      setState(() => _tab = selected.first),
                ),
              ],
            ),
          ),
          Expanded(
            child: _tab == 0
                ? _AttendanceHistory(timezone: timezone)
                : EmployeeLeaveRequestsPanel(timezone: timezone),
          ),
        ],
      ),
    );
  }
}
