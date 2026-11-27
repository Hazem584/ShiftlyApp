import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/eligible_shift_occurrence.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/dialogs/missed_attendance_request_dialog.dart';

import 'employee_active_attendance_screen.dart';
import 'employee_shift_status_eval.dart';

class EmployeeShiftDetailsFooter extends StatelessWidget {
  const EmployeeShiftDetailsFooter({
    required this.eval,
    required this.timezone,
    required this.onCheckIn,
    super.key,
  });

  final EmployeeShiftStatusEval eval;
  final String timezone;
  final ValueChanged<EligibleShiftOccurrence> onCheckIn;

  @override
  Widget build(BuildContext context) {
    final e = eval.entry;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (eval.safe && e.canClockIn)
          FilledButton(
            key: Key('eligible-template-${e.template.id}'),
            onPressed: () => onCheckIn(e),
            child: Text(context.tr('Check in')),
          ),
        if (eval.canReview)
          FilledButton(
            key: Key('review-missed-${e.identity}'),
            onPressed: () => _requestReview(context, e),
            child: Text(context.tr('Request attendance review')),
          ),
        if (eval.hasOpen)
          FilledButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) =>
                    EmployeeActiveAttendanceScreen(timezone: timezone),
              ),
            ),
            child: Text(context.tr('View attendance')),
          ),
        if (e.alreadyUsed)
          OutlinedButton(
            onPressed: () => context.push('/employee?tab=history'),
            child: Text(context.tr('View attendance history')),
          ),
        if (e.pendingReview)
          TextButton(
            onPressed: () => context.push('/team-work?tab=corrections'),
            child: Text(context.tr('View my requests')),
          ),
      ],
    );
  }

  Future<void> _requestReview(
    BuildContext context,
    EligibleShiftOccurrence e,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => MissedAttendanceRequestDialog(
        entry: e,
        workspaceId: eval.state.eligibility!.workspaceId,
        timezone: timezone,
        repository: getIt<TeamWorkRepository>(),
      ),
    );
    if (result == true && context.mounted) {
      await context.read<FlexibleAttendanceCubit>().load(refresh: true);
      if (context.mounted) context.push('/team-work?tab=corrections');
    }
  }
}
