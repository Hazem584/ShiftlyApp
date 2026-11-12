import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/employee_design.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/attendance_source.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/models/attendance_status_summary.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/legacy_clock_in_review_card.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/saved_schedule_list.dart';
import 'package:shiftly/features/shifts/presentation/screens/employee_shifts_screen.dart';

import 'employee_shift_details_screen.dart';

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
      return const SizedBox(height: 200, child: AppContentLoading());
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
            if (recovery != null) ...[
              const SizedBox(height: 12),
              Text(
                context.tr('Original request saved'),
                style: const TextStyle(color: EmployeeDesign.mint),
              ),
              SelectableText(
                recovery.clientAttendanceId,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: busy
                    ? null
                    : () => context
                          .read<FlexibleAttendanceCubit>()
                          .recoverClockIn(),
                child: Text(context.tr('Check original request')),
              ),
              TextButton(
                onPressed: () => Clipboard.setData(
                  ClipboardData(text: recovery.clientAttendanceId),
                ),
                child: Text(
                  context.tr('Copy request reference'),
                  style: const TextStyle(color: EmployeeDesign.mint),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/support'),
                child: Text(
                  context.tr('Get help'),
                  style: const TextStyle(color: EmployeeDesign.mint),
                ),
              ),
            ],
            if (state.failure != null) ...[
              const SizedBox(height: 10),
              Text(
                state.failure!.message,
                style: const TextStyle(color: EmployeeDesign.heroText),
              ),
            ],
            if (recovery == null) ...[
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: busy
                    ? null
                    : summary.occurrence != null
                    ? () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => EmployeeShiftDetailsScreen(
                            entry: summary.occurrence!,
                            timezone: timezone,
                          ),
                        ),
                      )
                    : () => context.go('/employee?tab=shifts'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: EmployeeDesign.mint,
                  side: const BorderSide(color: Color(0xFF414966)),
                ),
                child: Text(
                  context.tr(
                    summary.occurrence != null ? 'View shift' : 'View schedule',
                  ),
                ),
              ),
            ],
            if (state.failure != null || state.recoveryBlocked)
              TextButton(
                onPressed: busy
                    ? null
                    : () => context.read<FlexibleAttendanceCubit>().load(
                        refresh: true,
                      ),
                child: Text(
                  context.tr('Refresh'),
                  style: const TextStyle(color: EmployeeDesign.mint),
                ),
              ),
            if (state.current?.isOpen == true &&
                state.current?.source == AttendanceSource.legacyShift)
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: Text(context.tr('Earlier shifts'))),
                      body: const EmployeeShiftsScreen(),
                    ),
                  ),
                ),
                child: Text(
                  context.tr('Earlier shifts & clock-out'),
                  style: const TextStyle(color: EmployeeDesign.mint),
                ),
              ),
            if (state.legacyReviews.isNotEmpty)
              LegacyClockInReviewCard(
                reviews: state.legacyReviews,
                onRefresh: busy
                    ? null
                    : () => context.read<FlexibleAttendanceCubit>().load(
                        refresh: true,
                      ),
              ),
            if (state.failure != null && state.templates.isNotEmpty)
              SavedScheduleList(templates: state.templates),
          ],
        ),
      ),
    );
  }
}
