import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/manager_performance/domain/entities/manager_points_page.dart';
import 'package:shiftly/features/manager_performance/domain/entities/manager_points_record.dart';

abstract interface class ManagerPointsRepository {
  void bindSession(FeatureSessionScope? scope);
  Future<ManagerPointsPage> list(
    String workspace,
    String resource, {
    String? target,
    Map<String, Object?> query = const {},
  });
  Future<Map<String, Object?>> get(
    String workspace,
    String resource, {
    String? target,
  });
  Future<ManagerPointsRecord> mutate(
    String workspace,
    String resource,
    Map<String, Object?> payload, {
    String? target,
    bool patch = false,
  });
}
