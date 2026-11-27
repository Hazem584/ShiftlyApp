import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftly/core/serialization/api_model_parser.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';

String pendingClockInStorageKey(
  String userId,
  String workspaceId,
  String membershipId,
) => 'fixed_shift.pending_clock_in.v3.$userId.$workspaceId.$membershipId';

PendingClockIn? readPendingClockInRecord(
  SharedPreferences preferences, {
  required String userId,
  required String workspaceId,
  required String membershipId,
}) {
  final raw = preferences.getString(
    pendingClockInStorageKey(userId, workspaceId, membershipId),
  );
  if (raw == null) return null;
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

Future<void> writePendingClockInRecord(
  SharedPreferences preferences,
  PendingClockIn value,
) async {
  final key = pendingClockInStorageKey(
    value.userId,
    value.workspaceId,
    value.membershipId,
  );
  final existing = preferences.getString(key);
  if (existing != null) {
    final json = ApiModelParser.map(jsonDecode(existing));
    if (json['clientAttendanceId'] != value.clientAttendanceId ||
        jsonEncode(json['payload']) != jsonEncode(value.payload) ||
        json['operationalDate'] != value.operationalDate ||
        json['occurrenceKind'] != value.occurrenceKind) {
      throw StateError('Recover saved clock-in before creating another intent');
    }
  }
  final saved = await preferences.setString(
    key,
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
  if (!saved) throw StateError('Could not persist clock-in');
}
