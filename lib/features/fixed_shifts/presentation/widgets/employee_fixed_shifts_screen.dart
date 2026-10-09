import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/shifts/presentation/screens/employee_shifts_screen.dart';

import '../cubit/fixed_shifts_cubit.dart';
import 'flexible_attendance_panel.dart';

class EmployeeFixedShiftsScreen extends StatelessWidget {
  const EmployeeFixedShiftsScreen({super.key});
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
    return RefreshIndicator(
      onRefresh: () =>
          context.read<FlexibleAttendanceCubit>().load(refresh: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Fixed shifts',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text('Times in $timezone'),
          const SizedBox(height: 16),
          FlexibleAttendancePanel(timezone: timezone),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const Key('legacy-shift-history'),
            icon: const Icon(Icons.history),
            label: const Text('Legacy shift history / active clock-out'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Legacy shifts')),
                  body: const EmployeeShiftsScreen(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
