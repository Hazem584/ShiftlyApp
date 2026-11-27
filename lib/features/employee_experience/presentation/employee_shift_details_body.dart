import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/work_duration.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';

import 'employee_shift_status_eval.dart';
import 'employee_tile.dart';

class EmployeeShiftDetailsBody extends StatelessWidget {
  const EmployeeShiftDetailsBody({
    required this.eval,
    required this.timezone,
    super.key,
  });

  final EmployeeShiftStatusEval eval;
  final String timezone;

  @override
  Widget build(BuildContext context) {
    final e = eval.entry;
    final state = eval.state;
    final locale = Localizations.localeOf(context);
    String time(DateTime d) =>
        WorkspaceTime.time(d, timezone, locale: locale.toString());
    final kindLabel = e.scheduleExceptionId != null
        ? 'Date-specific change'
        : e.occurrenceKind == 'EXTRA'
        ? 'Authorized extra'
        : 'Baseline assignment';
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          '${e.operationalDate} · $timezone',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 28),
        EmployeeTile(
          title: e.template.name,
          subtitle:
              '${time(e.scheduledStartAt)}–${time(e.scheduledEndAt)} · ${context.tr(kindLabel)}',
          icon: Icons.calendar_today_outlined,
        ),
        const SizedBox(height: 14),
        EmployeeTile(
          title: context.tr('Check-in opens at {time}', {
            'time': time(e.checkInWindowStart),
          }),
          subtitle: context.tr('Latest check-in {time} · {minutes} min grace', {
            'time': time(e.checkInWindowEnd),
            'minutes': '${e.template.graceMinutes}',
          }),
        ),
        const SizedBox(height: 14),
        EmployeeTile(
          title: context.tr('Minimum work · {time}', {
            'time': workDuration(
              e.template.minimumWorkMinutes,
              arabic: locale.languageCode == 'ar',
            ),
          }),
          subtitle: context.tr('End of shift · {time}', {
            'time': time(e.scheduledEndAt),
          }),
          icon: Icons.timelapse_outlined,
        ),
        if (e.scheduleExceptionReason != null) ...[
          const SizedBox(height: 16),
          Text(e.scheduleExceptionReason!),
        ],
        if (eval.status != null) ...[
          const SizedBox(height: 24),
          Text(
            context.tr(eval.status!),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
        if (state.failure != null) ...[
          const SizedBox(height: 12),
          Text(
            state.failure!.message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          TextButton(
            onPressed: state.refreshing
                ? null
                : () => context.read<FlexibleAttendanceCubit>().load(
                    refresh: true,
                  ),
            child: Text(context.tr('Refresh')),
          ),
        ],
      ],
    );
  }
}
