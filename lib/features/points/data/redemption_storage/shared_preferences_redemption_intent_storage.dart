import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/points/data/points_models.dart';
import 'package:shiftly/features/points/data/redemption_storage/redemption_intent_storage_contract.dart';

class SharedPreferencesRedemptionIntentStorage
    implements RedemptionIntentStorage {
  SharedPreferencesRedemptionIntentStorage(this._preferences);

  static const _prefix = 'points_pending_redemption_v1';
  final SharedPreferences _preferences;

  String _key(FeatureSessionScope scope) =>
      '$_prefix:${scope.userId}:${scope.workspaceId}:${scope.membershipId}';

  @override
  Future<RedemptionIntent?> read(FeatureSessionScope scope) async {
    final value = _preferences.getString(_key(scope));
    if (value == null) return null;
    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) return null;
      final intent = RedemptionIntent.fromJson(
        Map<String, Object?>.from(decoded),
      );
      return intent.workspaceId == scope.workspaceId ? intent : null;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(FeatureSessionScope scope, RedemptionIntent intent) async {
    if (intent.workspaceId != scope.workspaceId) {
      throw StateError('Redemption intent does not match the active scope');
    }
    if (!await _preferences.setString(
      _key(scope),
      jsonEncode(intent.toJson()),
    )) {
      throw StateError('Unable to persist redemption intent');
    }
  }

  @override
  Future<void> clear(
    FeatureSessionScope scope,
    String clientRedemptionId,
  ) async {
    final current = await read(scope);
    if (current?.clientRedemptionId != clientRedemptionId) return;
    final removed = await _preferences.remove(_key(scope));
    if (!removed && _preferences.containsKey(_key(scope))) {
      throw StateError('Unable to clear redemption intent');
    }
  }
}
