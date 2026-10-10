import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/failure_notice.dart';
import 'package:shiftly/features/manager_performance/presentation/cubit/manager_performance_cubit.dart';
import 'package:shiftly/features/manager_performance/presentation/cubit/manager_performance_state.dart';
import 'package:shiftly/features/manager_performance/presentation/widgets/manager_confirmation_dialog.dart';
import 'package:shiftly/features/manager_performance/presentation/widgets/manager_operation_formatters.dart';

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
                Text(
                  context.tr('Saved operation: {value1}', {
                    'value1': managerOperationLabel(context, intent.resource),
                  }),
                ),
                if (intent.target != null)
                  Text(
                    context.tr('Employee membership: {value1}', {
                      'value1': (intent.target).toString(),
                    }),
                  ),
                Text(
                  context.tr(
                    'New changes are blocked until this operation is resolved.',
                  ),
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
                              details: managerOperationDetails(
                                context,
                                intent.payload,
                                resource: intent.resource,
                              ),
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
                        ? context.tr('Retry exact saved request')
                        : context.tr('Read canonical outcome'),
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
}
