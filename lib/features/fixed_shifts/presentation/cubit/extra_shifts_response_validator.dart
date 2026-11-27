import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/extra_authorization.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/extra_shift_intent.dart';

void validateExtraCreationResponse(
  FeatureSessionScope scope,
  ExtraShiftIntent intent,
  ExtraAuthorization canonical,
) {
  const validStatuses = {'AUTHORIZED', 'CONSUMED', 'REVOKED'};
  if (!validStatuses.contains(canonical.status) ||
      canonical.fields['workspaceId'] != scope.workspaceId ||
      canonical.fields['employeeMembershipId'] != intent.membershipId ||
      canonical.fields['createdByMembershipId'] != scope.membershipId ||
      canonical.fields['clientAuthorizationId'] !=
          intent.payload['clientAuthorizationId'] ||
      canonical.fields['shiftTemplateId'] !=
          intent.payload['shiftTemplateId'] ||
      canonical.operationalDate != intent.payload['operationalDate'] ||
      canonical.fields['reason'] != intent.payload['reason'] ||
      canonical.fields['explanation'] != intent.payload['explanation'] ||
      (intent.actual && canonical.status != 'CONSUMED')) {
    throw const FormatException('Invalid extra response');
  }
  if (!intent.actual) return;
  final attendance = canonical.fields['attendance'] as List;
  if (attendance.length != 1 || attendance.first is! Map) {
    throw const FormatException('Missing canonical attendance');
  }
  final linked = attendance.first as Map;
  final clockIn = DateTime.tryParse(
    canonical.fields['actualClockInAt'] as String? ?? '',
  );
  final clockOut = DateTime.tryParse(
    canonical.fields['actualClockOutAt'] as String? ?? '',
  );
  if (linked['extraAuthorizationId'] != canonical.id ||
      linked['enteredByMembershipId'] != scope.membershipId ||
      linked['occurrenceKind'] != 'EXTRA' ||
      linked['reviewStatus'] != 'APPROVED' ||
      clockIn != DateTime.parse(intent.payload['actualClockInAt'] as String) ||
      clockOut !=
          DateTime.parse(intent.payload['actualClockOutAt'] as String)) {
    throw const FormatException('Invalid manager attendance audit');
  }
}

void validateExtraRevocationResponse(
  FeatureSessionScope scope,
  String employee,
  ExtraAuthorization value,
  ExtraAuthorization canonical,
) {
  if (canonical.id != value.id ||
      canonical.status != 'REVOKED' ||
      canonical.fields['workspaceId'] != scope.workspaceId ||
      canonical.fields['employeeMembershipId'] != employee) {
    throw const FormatException('Invalid revocation response');
  }
}
