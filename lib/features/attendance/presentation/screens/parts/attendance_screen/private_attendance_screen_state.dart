part of '../../attendance_screen.dart';

class _AttendanceScreenState extends State<AttendanceScreen> {
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    if (_selectedTab == 2) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<AttendanceCalendarCubit>().open(),
      );
    }
  }

  @override
  void didUpdateWidget(covariant AttendanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _selectedTab = widget.initialTab;
      if (_selectedTab == 2) {
        context.read<AttendanceCalendarCubit>().open();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => switch (_selectedTab) {
            0 => context.read<ManagerAttendanceCubit>().load(refresh: true),
            1 => context.read<LeaveRequestsCubit>().load(refresh: true),
            _ => context.read<AttendanceCalendarCubit>().load(refresh: true),
          },
          child: ListView(
            key: const Key('attendance-content'),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
            children: [
              const ScreenHeader(
                icon: Icons.fact_check_rounded,
                title: 'Attendance & Leave',
                subtitle:
                    'Check who is in, review leave, and open the calendar',
              ),
              const SizedBox(height: AppSpacing.m),
              const AttendanceMetricsSection(),
              const SizedBox(height: AppSpacing.m),
              AttendanceTabSelector(
                selectedTab: _selectedTab,
                onSelected: (tab) {
                  setState(() => _selectedTab = tab);
                  if (tab == 2) {
                    context.read<AttendanceCalendarCubit>().open();
                  }
                },
              ),
              const SizedBox(height: AppSpacing.l),
              switch (_selectedTab) {
                0 => ManagerAttendancePanel(timezone: widget.timezone),
                1 => LeaveRequestsPanel(timezone: widget.timezone),
                _ => const AttendanceCalendarStateView(),
              },
            ],
          ),
        ),
      ),
    );
  }
}
