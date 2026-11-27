import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/employee_design.dart';
import 'package:shiftly/core/widgets/dashboard_card_loading.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/models/attendance_status_summary.dart';

import 'employee_attendance_gate_actions.dart';
import 'employee_attendance_recovery_section.dart';

class EmployeeAttendanceGate extends StatelessWidget {
  const EmployeeAttendanceGate({
    required this.state,
    required this.timezone,
    super.key,
  });
  final FlexibleAttendanceState state;
  final String timezone;

  @override
  Widget build(BuildContext context) {
    if (state.loading && state.current == null) {
      return const DashboardCardLoading(kind: DashboardCardKind.attendance);
    }
    final summary = AttendanceStatusSummary.fromState(
      state,
      actionLocation: 'in My Shifts',
    );
    final recovery = state.recovery;
    final exceptions = state.eligibility?.dayExceptions ?? const [];
    final closed = exceptions.any((n) => n.kind == 'HOLIDAY');
    final dayOff = exceptions.any((n) => n.kind == 'DAY_OFF');
    final title = recovery != null
        ? 'Still confirming your check-in.'
        : closed
        ? 'Your workspace is closed today'
        : dayOff
        ? 'Today is your day off'
        : summary.title;
    final busy =
        state.submittingTemplateId != null ||
        state.clockingOut ||
        state.refreshing;
    return Container(
      key: const Key('employee-attendance-gate'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? EmployeeDesign.heroDark
            : EmployeeDesign.hero,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(context).textTheme
              .apply(bodyColor: Colors.white, displayColor: Colors.white),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              recovery != null
                  ? Icons.sync
                  : closed || dayOff
                  ? Icons.event_busy_outlined
                  : Icons.schedule_outlined,
              color: EmployeeDesign.mint,
              size: 28,
            ),
            const SizedBox(height: 20),
            Text(
              context.tr(title, summary.arguments),
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              context.tr(summary.message, summary.arguments),
              style: const TextStyle(color: EmployeeDesign.heroText),
            ),
            for (final notice in exceptions) ...[
              const SizedBox(height: 8),
              Text(
                '${notice.operationalDate} · ${notice.reason}',
                style: const TextStyle(color: EmployeeDesign.heroText),
              ),
            ],
            if (recovery != null)
              EmployeeAttendanceRecoverySection(
                clientAttendanceId: recovery.clientAttendanceId,
                busy: busy,
              ),
            if (state.failure != null) ...[
              const SizedBox(height: 10),
              Text(
                state.failure!.message,
                style: const TextStyle(color: EmployeeDesign.heroText),
              ),
            ],
            EmployeeAttendanceGateActions(
              state: state,
              summary: summary,
              timezone: timezone,
              busy: busy,
            ),
          ],
        ),
      ),
    );
  }
}
