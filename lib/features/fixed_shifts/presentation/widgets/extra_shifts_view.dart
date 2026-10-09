import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/widgets/failure_notice.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/extra_authorization.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/extra_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/extra_shifts_state.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/extra_authorization_card.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/extra_shift_form.dart';

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
      return SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Extra Shifts',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh extra history',
                  onPressed: state.busy
                      ? null
                      : () => cubit.load(page: pagination?.page ?? 1),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const Text(
              'Extras require explicit manager authorization. They do not replace baseline attendance or automatically award BLUE.',
            ),
            if (state.loading) const LinearProgressIndicator(),
            if (state.failure != null)
              FailureNotice(
                failure: state.failure!,
                refreshing: state.loading,
                onRefresh: state.busy
                    ? null
                    : () => cubit.load(page: pagination?.page ?? 1),
              ),
            if (state.intent != null) ...[
              Text(
                'Saved ${state.intent!.actual ? 'actual attendance' : 'authorization'} for employee membership ${state.intent!.membershipId} on ${state.intent!.payload['operationalDate']}. Resolve this operation before creating another extra.',
              ),
              FilledButton.tonal(
                onPressed: state.busy ? null : cubit.recover,
                child: const Text('Recover saved extra operation'),
              ),
            ],
            if (state.canonical != null)
              ExpansionTile(
                title: const Text('Last saved canonical result'),
                children: [ExtraAuthorizationCard(value: state.canonical!)],
              ),
            if (state.page?.data.isEmpty == true)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No extra authorizations recorded.'),
              ),
            for (final value in state.page?.data ?? <ExtraAuthorization>[])
              ExtraAuthorizationCard(
                value: value,
                onRevoke:
                    canEdit &&
                        !state.busy &&
                        !state.loading &&
                        !state.recoveryBlocked &&
                        value.canRevoke
                    ? () => _revoke(context, value)
                    : null,
              ),
            if (pagination != null && pagination.totalPages > 1)
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TextButton(
                    onPressed:
                        state.loading || state.busy || pagination.page <= 1
                        ? null
                        : () => cubit.load(page: pagination.page - 1),
                    child: const Text('Previous'),
                  ),
                  Text('Page ${pagination.page} of ${pagination.totalPages}'),
                  TextButton(
                    onPressed:
                        state.loading ||
                            state.busy ||
                            pagination.page >= pagination.totalPages
                        ? null
                        : () => cubit.load(page: pagination.page + 1),
                    child: const Text('Next'),
                  ),
                ],
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed:
                      canEdit &&
                          !state.loading &&
                          !state.busy &&
                          !state.recoveryBlocked
                      ? () => _create(context, false)
                      : null,
                  icon: const Icon(Icons.more_time),
                  label: const Text('Authorize extra'),
                ),
                OutlinedButton.icon(
                  onPressed:
                      canEdit &&
                          !state.loading &&
                          !state.busy &&
                          !state.recoveryBlocked
                      ? () => _create(context, true)
                      : null,
                  icon: const Icon(Icons.edit_calendar),
                  label: const Text('Record actual attendance'),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
  Future<void> _create(BuildContext context, bool actual) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => ExtraShiftForm(
      repository: getIt<FixedShiftRepository>(),
      cubit: context.read<ExtraShiftsCubit>(),
      workspaceId: workspaceId,
      timezone: timezone,
      actual: actual,
    ),
  );
  Future<void> _revoke(BuildContext context, ExtraAuthorization value) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Revoke extra authorization?'),
        content: Text(
          '${value.schedule.name} · ${value.operationalDate}\nThis identity remains in audit history. The backend checks whether it has already been consumed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
    if (context.mounted && confirmed == true) {
      await context.read<ExtraShiftsCubit>().revoke(value);
    }
  }
}
