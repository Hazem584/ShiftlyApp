part of '../../employee_attendance_screen.dart';

class _EmployeeAttendanceScreenState extends State<EmployeeAttendanceScreen> {
  late int _tab;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
  }

  @override
  void didUpdateWidget(covariant EmployeeAttendanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) _tab = widget.initialTab;
  }

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
                AppTabSelector(
                  labels: const ['Attendance', 'Leave'],
                  selectedIndex: _tab,
                  onSelected: (selected) => setState(() => _tab = selected),
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
