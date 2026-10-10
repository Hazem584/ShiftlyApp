import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/manager_performance/presentation/cubit/manager_performance_cubit.dart';
import 'package:shiftly/features/manager_performance/presentation/cubit/manager_performance_state.dart';
import 'package:shiftly/features/manager_performance/presentation/widgets/manager_action_dialog.dart';
import 'package:shiftly/features/manager_performance/presentation/widgets/manager_forms.dart';
import 'package:shiftly/features/manager_performance/presentation/widgets/manager_recovery_banner.dart';

class ManagerDisputeScreen extends StatefulWidget {
  const ManagerDisputeScreen({required this.id, super.key});
  final String id;
  @override
  State<ManagerDisputeScreen> createState() => _ManagerDisputeScreenState();
}

class _ManagerDisputeScreenState extends State<ManagerDisputeScreen> {
  String get _resource => 'disputes/${widget.id}';
  @override
  void initState() {
    super.initState();
    context.read<ManagerPerformanceCubit>().load(_resource, object: true);
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<ManagerPerformanceCubit, ManagerPerformanceState>(
    listenWhen: (before, after) => before.scope != after.scope,
    listener: (context, state) =>
        context.read<ManagerPerformanceCubit>().load(_resource, object: true),
    builder: (context, state) {
      final cubit = context.read<ManagerPerformanceCubit>();
      final resource =
          state.resources[ManagerPerformanceCubit.key(_resource, null)];
      final record = resource?.object;
      final event = record?['targetLedgerEntry'];
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('Points dispute'))),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ManagerRecoveryBanner(cubit: cubit, state: state),
            if (state.scope == null)
              Text(context.tr('Manager access required.')),
            if (resource?.loading == true) const LinearProgressIndicator(),
            if (resource?.error case final error?) Text(context.tr(error)),
            TextButton(
              onPressed: resource?.loading == true
                  ? null
                  : () => cubit.load(_resource, object: true),
              child: Text(context.tr('Refresh detail')),
            ),
            if (record != null) ...[
              Text(
                context.tr('Status: {value1}', {
                  'value1': context.tr('${record['status'] ?? 'Unknown'}'),
                }),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                context.tr('Employee membership: {value1}', {
                  'value1': (record['employeeMembershipId'] ?? 'Unknown')
                      .toString(),
                }),
              ),
              Text(
                context.tr('Employee reason: {value1}', {
                  'value1': (record['reason'] ?? 'Unknown').toString(),
                }),
              ),
              if (event is Map)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      context.tr(
                        'Related immutable event\n{value1} {value2}\n{value3}\nOperational date: {value4}',
                        {
                          'value1': context.tr(
                            '${event['pointType'] ?? 'Unknown'}',
                          ),
                          'value2': (event['amount'] ?? 'Unknown').toString(),
                          'value3': context.tr(
                            '${event['reason'] ?? 'Unknown'}',
                          ),
                          'value4': (event['operationalDate'] ?? 'Unknown')
                              .toString(),
                        },
                      ),
                    ),
                  ),
                ),
              if (record['managerResponse'] != null)
                Text(
                  context.tr('Manager response: {value1}', {
                    'value1': (record['managerResponse']).toString(),
                  }),
                ),
              FilledButton(
                onPressed:
                    !state.canMutate ||
                        record['status'] != 'PENDING' ||
                        resource?.loading == true ||
                        resource?.error != null
                    ? null
                    : () async {
                        final scope = state.scope!;
                        final payload = await showDialog<Map<String, Object?>>(
                          context: context,
                          builder: (_) => ManagerActionDialog(
                            title: context.tr('Review dispute'),
                            fields: ManagerForms.review,
                            cubit: cubit,
                            scope: scope,
                          ),
                        );
                        if (payload != null &&
                            cubit.state.scope == scope &&
                            context.mounted) {
                          await cubit.submit(
                            '$_resource/review',
                            payload,
                            patch: true,
                          );
                          if (cubit.state.scope == scope) {
                            await cubit.load(_resource, object: true);
                          }
                        }
                      },
                child: Text(context.tr('Review dispute')),
              ),
            ],
          ],
        ),
      );
    },
  );
}
