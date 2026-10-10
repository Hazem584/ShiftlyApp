import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/manager_performance/domain/entities/manager_mutation_intent.dart';
import 'package:shiftly/features/manager_performance/presentation/cubit/manager_resource_state.dart';

class ManagerPerformanceState {
  const ManagerPerformanceState({
    this.scope,
    this.resources = const {},
    this.intent,
    this.restoring = false,
    this.busy = false,
    this.message,
    this.failure,
  });
  final FeatureSessionScope? scope;
  final Map<String, ManagerResourceState> resources;
  final ManagerMutationIntent? intent;
  final bool restoring, busy;
  final String? message;
  final Failure? failure;
  bool get canMutate =>
      scope?.isManager == true && !restoring && !busy && intent == null;
}
