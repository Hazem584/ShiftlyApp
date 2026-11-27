import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/extra_authorization_page.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/extra_shift_intent.dart';
import 'package:uuid/uuid.dart';

ExtraShiftIntent? buildExtraShiftIntent(
  String employeeId,
  Map<String, Object?> payload, {
  required bool actual,
}) {
  final allowed = {
    'shiftTemplateId',
    'operationalDate',
    'reason',
    'explanation',
    if (actual) 'actualClockInAt',
    if (actual) 'actualClockOutAt',
  };
  const validReasons = {
    'COVERED_EMPLOYEE',
    'ADDITIONAL_SHIFT',
    'APPROVED_OVERTIME',
    'EMERGENCY_SUPPORT',
    'HIGH_WORKLOAD_SUPPORT',
    'OTHER',
  };
  if (payload.keys.any((key) => !allowed.contains(key)) ||
      payload['explanation'] is! String ||
      payload['shiftTemplateId'] is! String ||
      payload['operationalDate'] is! String ||
      !validReasons.contains(payload['reason'])) {
    return null;
  }
  if (actual) {
    final start = DateTime.tryParse(
      payload['actualClockInAt'] as String? ?? '',
    );
    final end = DateTime.tryParse(payload['actualClockOutAt'] as String? ?? '');
    if (start == null ||
        end == null ||
        !end.isAfter(start) ||
        end.isAfter(DateTime.now().toUtc())) {
      return null;
    }
  }
  final normalized = Map<String, Object?>.from(payload);
  normalized['explanation'] = (normalized['explanation'] as String)
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
  normalized['clientAuthorizationId'] = const Uuid().v4();
  return ExtraShiftIntent(
    membershipId: employeeId,
    actual: actual,
    payload: normalized,
  );
}

void validateExtraPage(
  FeatureSessionScope scope,
  String employee,
  ExtraAuthorizationPage result,
) {
  if (result.data.any(
    (v) =>
        v.fields['workspaceId'] != scope.workspaceId ||
        v.fields['employeeMembershipId'] != employee,
  )) {
    throw const FormatException('Cross-scope extra response');
  }
}
