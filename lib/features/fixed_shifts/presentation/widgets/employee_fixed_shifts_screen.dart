import 'package:shiftly/core/utils/clock_time.dart';
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
          Text(
            'Available templates',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          BlocBuilder<FlexibleAttendanceCubit, FlexibleAttendanceState>(
            builder: (context, state) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!state.loading && state.templates.isEmpty)
                  const Text(
                    'No fixed templates are currently available. Pull to refresh.',
                  ),
                for (final template in state.templates)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${ClockTime.minutes(template.startMinute, locale: Localizations.localeOf(context).toString())} – ${ClockTime.minutes(template.endMinute, locale: Localizations.localeOf(context).toString())}${template.overnight ? ' (overnight)' : ''}',
                          ),
                          Text(
                            'Duration: ${template.durationMinutes ~/ 60}h ${template.durationMinutes % 60}m',
                          ),
                          Text(
                            'Grace: ${template.graceMinutes} min · Minimum work: ${template.minimumWorkMinutes} min',
                          ),
                          if (template.description != null)
                            Text(template.description!),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
