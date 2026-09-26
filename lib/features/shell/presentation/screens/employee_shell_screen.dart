import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/attendance/presentation/screens/employee_attendance_screen.dart';
import 'package:shiftly/features/shifts/presentation/screens/employee_shifts_screen.dart';

class EmployeeShellScreen extends StatefulWidget {
  const EmployeeShellScreen({super.key});

  @override
  State<EmployeeShellScreen> createState() => _EmployeeShellScreenState();
}

class _EmployeeShellScreenState extends State<EmployeeShellScreen> {
  var _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee workspace'),
        actions: [
          IconButton(
            key: const Key('employee-logout'),
            onPressed: context.read<SessionCoordinator>().signOut,
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: const [EmployeeShiftsScreen(), EmployeeAttendanceScreen()],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        key: const Key('employee-bottom-navigation'),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'My Shifts',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check_rounded),
            label: 'Attendance',
          ),
        ],
      ),
    );
  }
}
