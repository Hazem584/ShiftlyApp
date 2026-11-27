import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';
import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';
import 'package:shiftly/features/workspaces/domain/repositories/workspace_repository.dart';

String employeeStatusValue(EmployeeStatusFilter status) => switch (status) {
  EmployeeStatusFilter.active => 'ACTIVE',
  EmployeeStatusFilter.suspended => 'SUSPENDED',
};

String invitationStatusValue(InvitationStatus status) => switch (status) {
  InvitationStatus.pending => 'PENDING',
  InvitationStatus.accepted => 'ACCEPTED',
  InvitationStatus.revoked => 'REVOKED',
  InvitationStatus.expired => 'EXPIRED',
  InvitationStatus.unknown => throw ArgumentError('Unknown invitation status'),
};

InvitationStatus parseInvitationStatus(Object? value) => switch (value) {
  'PENDING' => InvitationStatus.pending,
  'ACCEPTED' => InvitationStatus.accepted,
  'REVOKED' => InvitationStatus.revoked,
  'EXPIRED' => InvitationStatus.expired,
  _ => InvitationStatus.unknown,
};

WorkspaceAccessRole parseWorkspaceRole(Object? value) => switch (value) {
  'MANAGER' => WorkspaceAccessRole.manager,
  'EMPLOYEE' => WorkspaceAccessRole.employee,
  _ => WorkspaceAccessRole.unknown,
};

Map<String, Object?> asJsonMap(Object? value) {
  if (value is! Map) throw const FormatException('Invalid response object');
  return Map<String, Object?>.from(value);
}

List<Object?> asJsonList(Object? value) {
  if (value is! List) throw const FormatException('Invalid response list');
  return value;
}

String readString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) throw FormatException('Invalid $key');
  return value;
}

int readInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int || value < 0) throw FormatException('Invalid $key');
  return value;
}

String? optionalString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

DateTime requiredDate(Map<String, Object?> json, String key) {
  final value = optionalDate(json[key]);
  if (value == null) throw FormatException('Invalid $key');
  return value;
}

DateTime? optionalDate(Object? value) {
  if (value == null) return null;
  final parsed = value is String ? DateTime.tryParse(value) : null;
  if (parsed == null) throw const FormatException('Invalid date');
  return parsed.toUtc();
}
