import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/manager_performance/domain/repositories/manager_intent_storage.dart';

class MemoryManagerIntentStorage implements ManagerIntentStorage {
  final Map<String, String> _values = {};
  String _key(FeatureSessionScope scope) =>
      '${scope.userId}|${scope.workspaceId}|${scope.membershipId}';
  @override
  Future<String?> read(FeatureSessionScope scope) async => _values[_key(scope)];
  @override
  Future<void> write(FeatureSessionScope scope, String value) async {
    _values[_key(scope)] = value;
  }

  @override
  Future<void> clear(FeatureSessionScope scope, String value) async {
    if (_values[_key(scope)] == value) {
      _values.remove(_key(scope));
    }
  }
}
