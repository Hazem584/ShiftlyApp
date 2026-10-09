import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
        appBar: AppBar(title: const Text('Points dispute')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ManagerRecoveryBanner(cubit: cubit, state: state),
            if (state.scope == null) const Text('Manager access required.'),
            if (resource?.loading == true) const LinearProgressIndicator(),
            if (resource?.error case final error?) Text(error),
            TextButton(
              onPressed: resource?.loading == true
                  ? null
                  : () => cubit.load(_resource, object: true),
              child: const Text('Refresh detail'),
            ),
            if (record != null) ...[
              Text(
                'Status: ${record['status'] ?? 'Unknown'}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                'Employee membership: ${record['employeeMembershipId'] ?? 'Unknown'}',
              ),
              Text('Employee reason: ${record['reason'] ?? 'Unknown'}'),
              if (event is Map)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Related immutable event\n${event['pointType'] ?? 'Unknown'} ${event['amount'] ?? 'Unknown'}\n${event['reason'] ?? 'Unknown'}\nOperational date: ${event['operationalDate'] ?? 'Unknown'}',
                    ),
                  ),
                ),
              if (record['managerResponse'] != null)
                Text('Manager response: ${record['managerResponse']}'),
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
                            title: 'Review dispute',
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
                child: const Text('Review dispute'),
              ),
            ],
          ],
        ),
      );
    },
  );
}
