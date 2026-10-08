import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/session/feature_scope.dart';

import 'manager_points_page.dart';
import 'manager_points_record.dart';
import 'manager_points_repository.dart';

/// Preview/test fallback explicitly reports unavailable data and actions.
class UnavailableManagerPointsRepository implements ManagerPointsRepository {
  const UnavailableManagerPointsRepository();
  @override
  void bindSession(FeatureSessionScope? scope) {}
  static const _error = ApiException(
    message: 'Manager Performance requires a connected backend.',
  );
  @override
  Future<Map<String, Object?>> get(
    String workspace,
    String resource, {
    String? target,
  }) async => throw _error;
  @override
  Future<ManagerPointsPage> list(
    String workspace,
    String resource, {
    String? target,
    Map<String, Object?> query = const {},
  }) async => throw _error;
  @override
  Future<ManagerPointsRecord> mutate(
    String workspace,
    String resource,
    Map<String, Object?> payload, {
    String? target,
    bool patch = false,
  }) async => throw _error;
}
