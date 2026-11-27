import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/fixed_shifts/data/legacy_clock_in_inspector.dart';
import 'package:shiftly/features/fixed_shifts/data/pending_clock_in_storage.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/legacy_clock_in_review.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';

class FixedShiftIntentStore {
  FixedShiftIntentStore(this._preferences, this.findPendingAttendance);
  final SharedPreferences _preferences;
  final Future<FlexibleAttendance?> Function(PendingClockIn)
  findPendingAttendance;

  Future<PendingClockIn?> loadPendingClockIn({
    required String userId,
    required String workspaceId,
    required String membershipId,
    required String templateId,
  }) async => readPendingClockInRecord(
    _preferences,
    userId: userId,
    workspaceId: workspaceId,
    membershipId: membershipId,
  );

  Future<List<LegacyClockInReview>> inspectLegacyClockIns(
    FeatureSessionScope scope,
  ) => inspectStoredLegacyClockIns(_preferences, findPendingAttendance, scope);

  Future<void> savePendingClockIn(PendingClockIn value) =>
      writePendingClockInRecord(_preferences, value);

  Future<void> clearPendingClockIn(PendingClockIn value) async {
    final existing = await loadPendingClockIn(
      userId: value.userId,
      workspaceId: value.workspaceId,
      membershipId: value.membershipId,
      templateId: value.templateId,
    );
    if (existing == null ||
        existing.clientAttendanceId != value.clientAttendanceId ||
        jsonEncode(existing.payload) != jsonEncode(value.payload) ||
        existing.operationalDate != value.operationalDate ||
        existing.occurrenceKind != value.occurrenceKind) {
      return;
    }
    final key = pendingClockInStorageKey(
      value.userId,
      value.workspaceId,
      value.membershipId,
    );
    final raw = _preferences.getString(key);
    if (raw == null) return;
    final latest = ApiModelParser.map(jsonDecode(raw));
    if (latest['userId'] != value.userId ||
        latest['workspaceId'] != value.workspaceId ||
        latest['membershipId'] != value.membershipId ||
        latest['templateId'] != value.templateId ||
        latest['clientAttendanceId'] != value.clientAttendanceId ||
        jsonEncode(latest['payload']) != jsonEncode(value.payload) ||
        latest['operationalDate'] != value.operationalDate ||
        latest['occurrenceKind'] != value.occurrenceKind) {
      return;
    }
    if (!await _preferences.remove(key) && _preferences.containsKey(key)) {
      throw StateError('Could not clear saved clock-in');
    }
  }

  String _extraKey(FeatureSessionScope s) =>
      'extra_shift.intent.v1:${s.userId}:${s.workspaceId}:${s.membershipId}';

  Future<String?> readExtraIntent(FeatureSessionScope scope) async =>
      _preferences.getString(_extraKey(scope));

  Future<void> saveExtraIntent(FeatureSessionScope scope, String intent) async {
    final existing = _preferences.getString(_extraKey(scope));
    if (existing != null && existing != intent) {
      throw StateError('Resolve the saved extra operation first');
    }
    if (!await _preferences.setString(_extraKey(scope), intent)) {
      throw StateError('Could not persist extra operation');
    }
  }

  Future<void> clearExtraIntent(
    FeatureSessionScope scope,
    String intent,
  ) async {
    final key = _extraKey(scope);
    if (_preferences.getString(key) != intent) return;
    if (!await _preferences.remove(key) && _preferences.containsKey(key)) {
      throw StateError('Could not clear saved operation');
    }
  }
}
