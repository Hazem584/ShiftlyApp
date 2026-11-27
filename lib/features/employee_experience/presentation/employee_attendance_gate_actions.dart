import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/employee_design.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/models/attendance_status_summary.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/saved_schedule_list.dart';

import 'employee_shift_details_screen.dart';

export 'package:shiftly/features/fixed_shifts/presentation/widgets/legacy_clock_in_review_card.dart';
export 'package:shiftly/features/shifts/presentation/screens/employee_shifts_screen.dart';

class EmployeeAttendanceGateActions extends StatelessWidget {
  const EmployeeAttendanceGateActions({
    required this.state,
    required this.summary,
    required this.timezone,
    required this.busy,
    super.key,
  });

  final FlexibleAttendanceState state;
  final AttendanceStatusSummary summary;
  final String timezone;
  final bool busy;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (state.recovery == null) ...[
        const SizedBox(height: 18),
        OutlinedButton(
          onPressed: state.submittingTemplateId != null || state.clockingOut
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
              : () =>
                    context.read<FlexibleAttendanceCubit>().load(refresh: true),
          child: Text(
            context.tr('Refresh'),
            style: const TextStyle(color: EmployeeDesign.mint),
          ),
        ),
      if (state.failure != null && state.templates.isNotEmpty)
        SavedScheduleList(templates: state.templates),
    ],
  );
}
