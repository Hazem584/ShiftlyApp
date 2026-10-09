import 'package:flutter/material.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/manager_performance/presentation/cubit/manager_performance_cubit.dart';
import 'package:shiftly/features/manager_performance/presentation/cubit/manager_performance_state.dart';

class ManagerConfirmationDialog extends StatelessWidget {
  const ManagerConfirmationDialog({
    required this.cubit,
    required this.scope,
    required this.title,
    required this.details,
    super.key,
  });
  final ManagerPerformanceCubit cubit;
  final FeatureSessionScope? scope;
  final String title, details;
  @override
  Widget build(BuildContext context) => StreamBuilder<ManagerPerformanceState>(
    stream: cubit.stream,
    initialData: cubit.state,
    builder: (context, snapshot) {
      final allowed = scope != null && snapshot.data?.scope == scope;
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(allowed ? details : 'Manager access changed.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: allowed ? () => Navigator.pop(context, true) : null,
            child: const Text('Confirm'),
          ),
        ],
      );
    },
  );
}
