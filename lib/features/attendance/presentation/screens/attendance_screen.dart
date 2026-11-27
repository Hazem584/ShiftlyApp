import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/features/attendance/presentation/cubit/attendance_calendar_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/leave_requests_cubit.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_cubit.dart';

import 'attendance_screen_content.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({
    this.initialTab = 0,
    this.timezone = 'Etc/UTC',
    super.key,
  });

  final int initialTab;
  final String timezone;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    if (_selectedTab != 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_selectedTab == 0) {
          context.read<AttendanceCalendarCubit>().showCurrentMonth();
        } else if (_selectedTab == 2) {
          context.read<AttendanceCalendarCubit>().open();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant AttendanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _selectedTab = widget.initialTab;
      if (_selectedTab == 0) {
        context.read<AttendanceCalendarCubit>().showCurrentMonth();
      } else if (_selectedTab == 2) {
        context.read<AttendanceCalendarCubit>().open();
      }
    }
  }

  Future<void> _refreshAttendance() async {
    await Future.wait([
      context.read<ManagerAttendanceCubit>().load(refresh: true),
      context.read<AttendanceCalendarCubit>().showCurrentMonth(),
    ]);
  }

  Future<void> _refresh() => switch (_selectedTab) {
    0 => _refreshAttendance(),
    1 => context.read<LeaveRequestsCubit>().load(refresh: true),
    _ => context.read<AttendanceCalendarCubit>().load(refresh: true),
  };

  void _selectTab(int tab) {
    setState(() => _selectedTab = tab);
    if (tab == 0) {
      context.read<AttendanceCalendarCubit>().showCurrentMonth();
    } else if (tab == 2) {
      context.read<AttendanceCalendarCubit>().open();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: AttendanceScreenContent(
          selectedTab: _selectedTab,
          timezone: widget.timezone,
          onRefresh: _refresh,
          onSelected: _selectTab,
        ),
      ),
    ),
  );
}
