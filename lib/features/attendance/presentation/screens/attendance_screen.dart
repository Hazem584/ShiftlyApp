import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/screen_header.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_calendar_state.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_metrics_section.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_records_list.dart';
import 'package:shiftly/features/attendance/presentation/widgets/attendance_tab_selector.dart';
import 'package:shiftly/features/attendance/presentation/widgets/leave_requests_panel.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({this.initialTab = 0, super.key});

  final int initialTab;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late int _selectedTab;

  static const _records = [
    AttendanceItem(
      day: '15',
      weekday: 'Monday',
      checkIn: '09:00',
      checkOut: '17:30',
      hours: '8.5h',
      location: 'Office',
    ),
    AttendanceItem(
      day: '14',
      weekday: 'Sunday',
      checkIn: '09:15',
      checkOut: '17:45',
      hours: '8.5h',
      location: 'Office',
    ),
    AttendanceItem(
      day: '13',
      weekday: 'Saturday',
      checkIn: '09:00',
      checkOut: '17:00',
      hours: '8h',
      location: 'Remote',
    ),
    AttendanceItem(
      day: '12',
      weekday: 'Friday',
      checkIn: '—',
      checkOut: '—',
      hours: '0h',
      location: '—',
      status: 'Sick Leave',
    ),
    AttendanceItem(
      day: '11',
      weekday: 'Thursday',
      checkIn: '09:30',
      checkOut: '18:00',
      hours: '8.5h',
      location: 'Office',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  void didUpdateWidget(covariant AttendanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _selectedTab = widget.initialTab;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        key: const Key('attendance-content'),
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
        children: [
          const ScreenHeader(
            title: 'Attendance & Leave',
            subtitle: 'Track attendance and manage leave requests',
          ),
          const SizedBox(height: AppSpacing.m),
          const AttendanceMetricsSection(),
          const SizedBox(height: AppSpacing.m),
          AttendanceTabSelector(
            selectedTab: _selectedTab,
            onSelected: (tab) => setState(() => _selectedTab = tab),
          ),
          const SizedBox(height: AppSpacing.l),
          switch (_selectedTab) {
            0 => const AttendanceRecordsList(records: _records),
            1 => const LeaveRequestsPanel(),
            _ => const AttendanceCalendarState(),
          },
        ],
      ),
    ),
  );
}
