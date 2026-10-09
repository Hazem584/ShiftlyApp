import 'package:shiftly/core/session/feature_scope.dart';

abstract interface class ManagerIntentStorage {
  Future<String?> read(FeatureSessionScope scope);
  Future<void> write(FeatureSessionScope scope, String value);
  Future<void> clear(FeatureSessionScope scope, String value);
}
