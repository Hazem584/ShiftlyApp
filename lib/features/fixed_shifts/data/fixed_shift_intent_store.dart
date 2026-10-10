import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/legacy_clock_in_review.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';

class FixedShiftIntentStore {
  FixedShiftIntentStore(this._preferences, this.findPendingAttendance);
  final SharedPreferences _preferences;
  final Future<FlexibleAttendance?> Function(PendingClockIn)
  findPendingAttendance;
  static const _legacyPendingKey = 'fixed_shift.pending_clock_in.v1';
  static const _pendingPrefix = 'fixed_shift.pending_clock_in.v2';
  Future<PendingClockIn?> loadPendingClockIn({
    required String userId,
    required String workspaceId,
    required String membershipId,
    required String templateId,
  }) async {
    final key = _pendingKey(userId, workspaceId, membershipId, templateId);
    final raw = _preferences.getString(key);
    if (raw == null) {
      return null;
    }
    final json = ApiModelParser.map(jsonDecode(raw));
    final pending = PendingClockIn(
      userId: ApiModelParser.string(json, 'userId'),
      workspaceId: ApiModelParser.string(json, 'workspaceId'),
      membershipId: ApiModelParser.string(json, 'membershipId'),
      templateId: ApiModelParser.string(json, 'templateId'),
      clientAttendanceId: ApiModelParser.string(json, 'clientAttendanceId'),
      occurrenceKind: ApiModelParser.optionalString(json['occurrenceKind']),
      assignmentId: ApiModelParser.optionalString(json['assignmentId']),
      extraAuthorizationId: ApiModelParser.optionalString(
        json['extraAuthorizationId'],
      ),
      operationalDate: ApiModelParser.optionalString(json['operationalDate']),
    );
    if (pending.userId != userId ||
        pending.workspaceId != workspaceId ||
        pending.membershipId != membershipId ||
        !pending.hasEvidence) {
      throw const FormatException('Stored attendance needs review');
    }
    if (jsonEncode(json['payload']) != jsonEncode(pending.payload)) {
      throw const FormatException(
        'Saved payload does not match occurrence evidence',
      );
    }
    return pending;
  }

  Future<List<LegacyClockInReview>> inspectLegacyClockIns(
    FeatureSessionScope scope,
  ) async {
    final reviews = <LegacyClockInReview>[];
    final prefix =
        '$_pendingPrefix.${scope.userId}.${scope.workspaceId}.${scope.membershipId}.';
    final keys =
        _preferences
            .getKeys()
            .where((key) => key == _legacyPendingKey || key.startsWith(prefix))
            .toList()
          ..sort();
    for (final key in keys) {
      String? clientId;
      try {
        final json = ApiModelParser.map(
          jsonDecode(_preferences.getString(key)!),
        );
        // v1 and v2 stored these five fields, without occurrence/date evidence.
        final pending = PendingClockIn(
          userId: ApiModelParser.string(json, 'userId'),
          workspaceId: ApiModelParser.string(json, 'workspaceId'),
          membershipId: ApiModelParser.string(json, 'membershipId'),
          templateId: ApiModelParser.string(json, 'templateId'),
          clientAttendanceId: ApiModelParser.string(json, 'clientAttendanceId'),
        );
        if (key != _legacyPendingKey &&
            key !=
                '$_pendingPrefix.${pending.userId}.${pending.workspaceId}.${pending.membershipId}.${pending.templateId}') {
          throw const FormatException('Legacy key and owner disagree');
        }
        if (pending.userId != scope.userId ||
            pending.workspaceId != scope.workspaceId ||
            pending.membershipId != scope.membershipId) {
          continue;
        }
        clientId = pending.clientAttendanceId;
        if (!RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
        ).hasMatch(clientId)) {
          throw const FormatException('Invalid legacy request ID');
        }
        final canonical = await findPendingAttendance(pending);
        if (canonical != null &&
            (canonical.workspaceId != scope.workspaceId ||
                canonical.employeeMembershipId != scope.membershipId ||
                canonical.shiftTemplateId != pending.templateId ||
                canonical.clientAttendanceId != clientId)) {
          throw const FormatException('Legacy canonical owner mismatch');
        }
        reviews.add(
          LegacyClockInReview(
            storageKey: key,
            clientAttendanceId: clientId,
            canonical: canonical,
            message: canonical == null
                ? 'Saved legacy clock-in needs review. No matching attendance was found. Refresh to check again, or contact support with request ID $clientId and this workspace. Its original occurrence was not saved, so this app cannot safely retry it. The saved record is retained.'
                : 'Saved legacy clock-in confirmed as attendance ${canonical.id}. The original record is retained for audit and will never be resubmitted.',
          ),
        );
      } catch (_) {
        reviews.add(
          LegacyClockInReview(
            storageKey: key,
            clientAttendanceId: clientId,
            message: clientId == null
                ? 'Saved legacy clock-in needs review: its owner or request evidence cannot be verified. Contact support to inspect the saved record on this device. It is retained and cannot be replayed or safely dismissed here. Refresh after support resolves it.'
                : 'Saved legacy clock-in needs review. Confirmation is unavailable; restore access and refresh, or contact support with request ID $clientId. The original record is retained and will not be resubmitted.',
          ),
        );
      }
    }
    return reviews;
  }

  Future<void> savePendingClockIn(PendingClockIn value) async {
    final key = _pendingKey(
      value.userId,
      value.workspaceId,
      value.membershipId,
      value.templateId,
    );
    final existing = _preferences.getString(key);
    if (existing != null) {
      final json = ApiModelParser.map(jsonDecode(existing));
      if (json['clientAttendanceId'] != value.clientAttendanceId ||
          jsonEncode(json['payload']) != jsonEncode(value.payload) ||
          json['operationalDate'] != value.operationalDate ||
          json['occurrenceKind'] != value.occurrenceKind) {
        throw StateError(
          'Recover saved clock-in before creating another intent',
        );
      }
    }
    final saved = await _preferences.setString(
      _pendingKey(
        value.userId,
        value.workspaceId,
        value.membershipId,
        value.templateId,
      ),
      jsonEncode({
        'userId': value.userId,
        'workspaceId': value.workspaceId,
        'membershipId': value.membershipId,
        'templateId': value.templateId,
        'clientAttendanceId': value.clientAttendanceId,
        'payload': value.payload,
        'occurrenceKind': value.occurrenceKind,
        'assignmentId': value.assignmentId,
        'extraAuthorizationId': value.extraAuthorizationId,
        'operationalDate': value.operationalDate,
      }),
    );
    if (!saved) {
      throw StateError('Could not persist clock-in');
    }
  }

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
    // Recheck synchronously after the awaited decode. No other intent may
    // replace this one between ownership validation and starting removal.
    final key = _pendingKey(
      value.userId,
      value.workspaceId,
      value.membershipId,
      value.templateId,
    );
    final raw = _preferences.getString(key);
    if (raw == null) {
      return;
    }
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
    final removed = await _preferences.remove(
      _pendingKey(
        value.userId,
        value.workspaceId,
        value.membershipId,
        value.templateId,
      ),
    );
    if (!removed &&
        _preferences.containsKey(
          _pendingKey(
            value.userId,
            value.workspaceId,
            value.membershipId,
            value.templateId,
          ),
        )) {
      throw StateError('Could not clear saved clock-in');
    }
  }

  String _pendingKey(
    String userId,
    String workspaceId,
    String membershipId,
    String templateId,
  ) => 'fixed_shift.pending_clock_in.v3.$userId.$workspaceId.$membershipId';

  String _extraKey(FeatureSessionScope scope) =>
      'extra_shift.intent.v1:${scope.userId}:${scope.workspaceId}:${scope.membershipId}';

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
    // Keep comparison and the start of removal in the same synchronous turn.
    if (_preferences.getString(_extraKey(scope)) != intent) {
      return;
    }
    if (!await _preferences.remove(_extraKey(scope)) &&
        _preferences.containsKey(_extraKey(scope))) {
      throw StateError('Could not clear saved operation');
    }
  }
}
