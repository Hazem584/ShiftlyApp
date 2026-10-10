import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/failure_notice.dart';
import 'package:shiftly/features/manager_performance/presentation/cubit/manager_performance_cubit.dart';
import 'package:shiftly/features/manager_performance/presentation/cubit/manager_performance_state.dart';
import 'package:shiftly/features/manager_performance/presentation/widgets/manager_confirmation_dialog.dart';

class ManagerRecoveryBanner extends StatelessWidget {
  const ManagerRecoveryBanner({
    required this.cubit,
    required this.state,
    super.key,
  });
  final ManagerPerformanceCubit cubit;
  final ManagerPerformanceState state;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (state.busy || state.restoring) const LinearProgressIndicator(),
      if (state.failure != null) ...[
        FailureNotice(failure: state.failure!),
        if (state.failure!.code != null)
          SelectableText(
            context.tr('Error code: {code}', {'code': state.failure!.code!}),
          ),
      ] else if (state.message != null)
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(context.tr(state.message!)),
        ),
      if (state.intent case final intent?)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Saved operation: ${intent.resource}'),
                if (intent.target != null)
                  Text('Employee membership: ${intent.target}'),
                Text(
                  'New changes are blocked until this operation is resolved.',
                ),
                OutlinedButton(
                  onPressed: state.busy || state.restoring
                      ? null
                      : () async {
                          final scope = state.scope;
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (_) => ManagerConfirmationDialog(
                              cubit: cubit,
                              scope: scope,
                              title: intent.hasUuid
                                  ? 'Retry saved operation?'
                                  : 'Check canonical outcome?',
                              details: intent.payload.entries
                                  .map(
                                    (entry) => '${entry.key}: ${entry.value}',
                                  )
                                  .join('\n\n'),
                            ),
                          );
                          if (confirmed == true &&
                              cubit.state.scope == scope &&
                              identical(cubit.state.intent, intent)) {
                            await cubit.recover();
                          }
                        },
                  child: Text(
                    intent.hasUuid
                        ? 'Retry exact saved request'
                        : 'Read canonical outcome',
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}
