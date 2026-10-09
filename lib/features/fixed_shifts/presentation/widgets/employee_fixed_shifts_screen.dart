import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/screen_header.dart';
import 'package:shiftly/core/widgets/ease_hint.dart';
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
          ScreenHeader(
            icon: Icons.calendar_month_rounded,
            title: 'Fixed shifts',
            subtitle: 'Your workday, in one place · Times in $timezone',
          ),
          const SizedBox(height: AppSpacing.m),
          const EaseHint(
            icon: Icons.fingerprint_rounded,
            message: 'Choose an available shift to clock in. Your active shift will show the clock-out action.',
          ),
          const SizedBox(height: AppSpacing.m),
          FlexibleAttendancePanel(timezone: timezone),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const Key('legacy-shift-history'),
            icon: const Icon(Icons.history),
            label: const Text('Earlier shifts & clock-out'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Earlier shifts')),
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
