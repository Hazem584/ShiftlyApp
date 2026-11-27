import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';

Widget buildFlexibleRecoveryCard(
  BuildContext context,
  FlexibleAttendanceState state,
) => SurfaceCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(context.tr('Clock-in outcome needs confirmation')),
      Text(
        context.tr(
          'We could not confirm your clock-in. Connect and check its status before starting another shift.',
        ),
      ),
      FilledButton(
        onPressed: state.submittingTemplateId != null
            ? null
            : () => context.read<FlexibleAttendanceCubit>().recoverClockIn(),
        child: Text(context.tr('Recover saved clock-in')),
      ),
    ],
  ),
);

Widget buildUnactionableOpenAttendanceCard(
  BuildContext context,
  FlexibleAttendance current,
) {
  final isLegacy = current.source == AttendanceSource.legacyShift;
  return SurfaceCard(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          isLegacy
              ? Icons.event_available_outlined
              : Icons.help_outline_rounded,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr(
                  isLegacy
                      ? 'Legacy shift attendance is active'
                      : 'Active attendance is unavailable',
                ),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                context.tr(
                  isLegacy
                      ? 'Open My Shifts, then Legacy shift history / active clock-out to finish this attendance.'
                      : 'Refresh before taking another attendance action.',
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
