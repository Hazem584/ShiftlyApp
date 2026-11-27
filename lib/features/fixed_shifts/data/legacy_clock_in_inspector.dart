import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/legacy_clock_in_review.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';

const _legacyPendingKey = 'fixed_shift.pending_clock_in.v1';
const _pendingPrefix = 'fixed_shift.pending_clock_in.v2';
final _uuidV4Regex = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);

Future<List<LegacyClockInReview>> inspectStoredLegacyClockIns(
  SharedPreferences preferences,
  Future<FlexibleAttendance?> Function(PendingClockIn) findPendingAttendance,
  FeatureSessionScope scope,
) async {
  final reviews = <LegacyClockInReview>[];
  final prefix =
      '$_pendingPrefix.${scope.userId}.${scope.workspaceId}.${scope.membershipId}.';
  final keys =
      preferences
          .getKeys()
          .where((k) => k == _legacyPendingKey || k.startsWith(prefix))
          .toList()
        ..sort();
  for (final key in keys) {
    final review = await _inspectSingleKey(
      preferences,
      findPendingAttendance,
      scope,
      key,
    );
    if (review != null) reviews.add(review);
  }
  return reviews;
}

Future<LegacyClockInReview?> _inspectSingleKey(
  SharedPreferences preferences,
  Future<FlexibleAttendance?> Function(PendingClockIn) findPendingAttendance,
  FeatureSessionScope scope,
  String key,
) async {
  String? clientId;
  try {
    final json = ApiModelParser.map(jsonDecode(preferences.getString(key)!));
    final p = PendingClockIn(
      userId: ApiModelParser.string(json, 'userId'),
      workspaceId: ApiModelParser.string(json, 'workspaceId'),
      membershipId: ApiModelParser.string(json, 'membershipId'),
      templateId: ApiModelParser.string(json, 'templateId'),
      clientAttendanceId: ApiModelParser.string(json, 'clientAttendanceId'),
    );
    final expectedKey =
        '$_pendingPrefix.${p.userId}.${p.workspaceId}.${p.membershipId}.${p.templateId}';
    if (key != _legacyPendingKey && key != expectedKey) {
      throw const FormatException('Legacy key and owner disagree');
    }
    if (p.userId != scope.userId ||
        p.workspaceId != scope.workspaceId ||
        p.membershipId != scope.membershipId) {
      return null;
    }
    clientId = p.clientAttendanceId;
    if (!_uuidV4Regex.hasMatch(clientId)) {
      throw const FormatException('Invalid legacy request ID');
    }
    final canonical = await findPendingAttendance(p);
    if (canonical != null &&
        (canonical.workspaceId != scope.workspaceId ||
            canonical.employeeMembershipId != scope.membershipId ||
            canonical.shiftTemplateId != p.templateId ||
            canonical.clientAttendanceId != clientId)) {
      throw const FormatException('Legacy canonical owner mismatch');
    }
    return LegacyClockInReview(
      storageKey: key,
      clientAttendanceId: clientId,
      canonical: canonical,
      message: canonical == null
          ? 'Saved legacy clock-in needs review. No matching attendance was found. Refresh to check again, or contact support with request ID $clientId and this workspace. Its original occurrence was not saved, so this app cannot safely retry it. The saved record is retained.'
          : 'Saved legacy clock-in confirmed as attendance ${canonical.id}. The original record is retained for audit and will never be resubmitted.',
    );
  } catch (_) {
    return LegacyClockInReview(
      storageKey: key,
      clientAttendanceId: clientId,
      message: clientId == null
          ? 'Saved legacy clock-in needs review: its owner or request evidence cannot be verified. Contact support to inspect the saved record on this device. It is retained and cannot be replayed or safely dismissed here. Refresh after support resolves it.'
          : 'Saved legacy clock-in needs review. Confirmation is unavailable; restore access and refresh, or contact support with request ID $clientId. The original record is retained and will not be resubmitted.',
    );
  }
}
