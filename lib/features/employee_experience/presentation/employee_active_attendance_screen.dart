import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/work_duration.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';

import 'employee_attendance_actions.dart';
import 'employee_attendance_gate.dart';
import 'employee_attendance_hero.dart';
import 'employee_break_panel.dart';
import 'employee_page.dart';

class EmployeeActiveAttendanceScreen extends StatelessWidget {
  const EmployeeActiveAttendanceScreen({
    required this.timezone,
    this.now,
    super.key,
  });
  final String timezone;
  final DateTime Function()? now;
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<FlexibleAttendanceCubit, FlexibleAttendanceState>(
    builder: (context, state) {
      final a = state.current;
      if (a == null || !a.isActionable || state.recovery != null) {
        return EmployeePage(
          title: 'Active attendance',
          child: EmployeeAttendanceGate(state: state, timezone: timezone),
        );
      }
      final complete = !a.isOpen;
      final safe =
          !state.clockingOut &&
          !state.refreshing &&
          !state.loading &&
          !state.recoveryBlocked &&
          state.failure == null;
      return EmployeePage(
        title: complete ? 'Shift complete' : 'Active attendance',
        footer: complete
            ? FilledButton(
                onPressed: () => context.go('/employee?tab=history'),
                child: Text(context.tr('View attendance history')),
              )
            : FilledButton(
                key: const Key('employee-check-out'),
                onPressed: safe ? () => employeeClockOut(context) : null,
                child: Text(
                  context.tr(
                    state.clockingOut
                        ? 'Confirming your clock-out'
                        : 'Check out',
                  ),
                ),
              ),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              '${a.operationalDate ?? ''} · ${a.templateName ?? ''}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            if (complete) ...[
              const Icon(Icons.check_circle_outline, size: 64),
              const SizedBox(height: 20),
              Text(
                context.tr('You’re all done.'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                '${WorkspaceTime.time(a.clockInAt, timezone)} → ${WorkspaceTime.time(a.clockOutAt, timezone)} · $timezone',
              ),
              Text(
                workDurationWithOvertime(
                  a.netWorkedMinutes ?? a.workedMinutes ?? 0,
                  a.overtimeMinutes,
                  arabic: Localizations.localeOf(context).languageCode == 'ar',
                ),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                context.tr(
                  a.reviewStatus == 'APPROVED' ? 'Approved' : 'Pending review',
                ),
              ),
            ] else ...[
              EmployeeAttendanceHero(
                attendance: a,
                timezone: timezone,
                now: now,
              ),
              const SizedBox(height: 30),
              if (safe) EmployeeBreakPanel(attendance: a, timezone: timezone),
            ],
            if (state.failure != null) ...[
              const SizedBox(height: 16),
              Text(
                state.failure!.message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              OutlinedButton(
                onPressed: () =>
                    context.read<FlexibleAttendanceCubit>().load(refresh: true),
                child: Text(context.tr('Refresh')),
              ),
            ],
          ],
        ),
      );
    },
  );
}
