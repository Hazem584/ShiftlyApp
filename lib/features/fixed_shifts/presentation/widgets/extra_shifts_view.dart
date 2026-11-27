import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/extra_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/extra_shifts_state.dart';

import 'extra_shift_dialogs.dart';
import 'extra_shift_history.dart';
import 'extra_shift_operation_status.dart';

class ExtraShiftsView extends StatelessWidget {
  const ExtraShiftsView({
    required this.workspaceId,
    required this.timezone,
    required this.canEdit,
    super.key,
  });
  final String workspaceId, timezone;
  final bool canEdit;
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<ExtraShiftsCubit, ExtraShiftsState>(
    builder: (context, state) {
      final cubit = context.read<ExtraShiftsCubit>();
      final pagination = state.page?.pagination;
      final canCreate =
          canEdit && !state.loading && !state.busy && !state.recoveryBlocked;
      return SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('Extra Shifts'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: context.tr('Refresh extra history'),
                  onPressed: state.busy
                      ? null
                      : () => cubit.load(page: pagination?.page ?? 1),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            Text(
              context.tr(
                'Extra shifts require explicit manager authorization and are recorded separately from regular attendance.',
              ),
            ),
            ...extraShiftOperationStatus(
              context,
              cubit,
              state,
              pagination?.page ?? 1,
            ),
            ...extraShiftHistory(
              context,
              cubit,
              state,
              canEdit: canEdit,
              onRevoke: (value) => revokeExtraShift(context, value),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: canCreate ? () => _showForm(context, false) : null,
                  icon: const Icon(Icons.more_time),
                  label: Text(context.tr('Authorize extra')),
                ),
                OutlinedButton.icon(
                  onPressed: canCreate ? () => _showForm(context, true) : null,
                  icon: const Icon(Icons.edit_calendar),
                  label: Text(context.tr('Record actual attendance')),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );

  Future<void> _showForm(BuildContext context, bool actual) =>
      showExtraShiftForm(
        context,
        workspaceId: workspaceId,
        timezone: timezone,
        actual: actual,
      );
}
