import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/manager_performance/domain/entities/manager_points_page.dart';
import 'package:shiftly/features/manager_performance/domain/entities/manager_points_record.dart';
import 'package:shiftly/features/manager_performance/domain/repositories/manager_points_repository.dart';

class ManagerPointsFake implements ManagerPointsRepository {
  @override
  void bindSession(FeatureSessionScope? scope) {}
  final List<Map<String, Object?>> calls = [];
  Future<ManagerPointsPage> Function(String, String?, Map<String, Object?>)?
  onList;
  Future<Map<String, Object?>> Function(String, String?)? onGet;
  Future<ManagerPointsRecord> Function(String, Map<String, Object?>, String?)?
  onMutate;
  @override
  Future<ManagerPointsPage> list(
    String workspace,
    String resource, {
    String? target,
    Map<String, Object?> query = const {},
  }) async {
    calls.add({
      'method': 'GET',
      'workspace': workspace,
      'resource': resource,
      'target': target,
      'query': query,
    });
    return onList == null
        ? const ManagerPointsPage([])
        : await onList!(resource, target, query);
  }

  @override
  Future<Map<String, Object?>> get(
    String workspace,
    String resource, {
    String? target,
  }) async {
    calls.add({
      'method': 'GET',
      'workspace': workspace,
      'resource': resource,
      'target': target,
    });
    return onGet == null
        ? {'id': resource, 'workspaceId': workspace, 'status': 'PENDING'}
        : await onGet!(resource, target);
  }

  @override
  Future<ManagerPointsRecord> mutate(
    String workspace,
    String resource,
    Map<String, Object?> payload, {
    String? target,
    bool patch = false,
  }) async {
    calls.add({
      'method': patch ? 'PATCH' : 'POST',
      'workspace': workspace,
      'resource': resource,
      'target': target,
      'payload': Map<String, Object?>.from(payload),
    });
    return onMutate == null
        ? ManagerPointsRecord({
            'id': 'result',
            'workspaceId': workspace,
            ...payload,
          })
        : await onMutate!(resource, payload, target);
  }
}
