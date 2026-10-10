import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/ease_hint.dart';
import 'package:shiftly/core/widgets/screen_header.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/flexible_attendance_panel.dart';
import 'package:shiftly/features/shifts/presentation/screens/employee_shifts_screen.dart';

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
            title: context.tr('Fixed shifts'),
            subtitle: context.tr(
              'Your workday, in one place · Times in {timezone}',
              {'timezone': timezone},
            ),
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
            label: Text(context.tr('Earlier shifts & clock-out')),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: Text(context.tr('Earlier shifts'))),
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
