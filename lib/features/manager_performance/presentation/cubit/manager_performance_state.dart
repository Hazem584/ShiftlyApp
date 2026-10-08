import 'package:shiftly/core/session/feature_scope.dart';

import '../../data/manager_mutation_intent.dart';
import 'manager_resource_state.dart';

class ManagerPerformanceState {
  const ManagerPerformanceState({
    this.scope,
    this.resources = const {},
    this.intent,
    this.restoring = false,
    this.busy = false,
    this.message,
  });
  final FeatureSessionScope? scope;
  final Map<String, ManagerResourceState> resources;
  final ManagerMutationIntent? intent;
  final bool restoring, busy;
  final String? message;
  bool get canMutate =>
      scope?.isManager == true && !restoring && !busy && intent == null;
}
