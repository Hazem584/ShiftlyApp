import 'package:flutter/material.dart';
import 'package:shiftly/core/session/feature_scope.dart';

import '../cubit/manager_performance_cubit.dart';
import '../cubit/manager_performance_state.dart';

class ManagerScopedDetails extends StatelessWidget {
  const ManagerScopedDetails({
    required this.cubit,
    required this.scope,
    required this.child,
    super.key,
  });
  final ManagerPerformanceCubit cubit;
  final FeatureSessionScope? scope;
  final Widget child;
  @override
  Widget build(BuildContext context) => StreamBuilder<ManagerPerformanceState>(
    stream: cubit.stream,
    initialData: cubit.state,
    builder: (context, snapshot) =>
        snapshot.data?.scope == scope && scope != null
        ? child
        : AlertDialog(
            title: const Text('Manager access changed.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
  );
}
