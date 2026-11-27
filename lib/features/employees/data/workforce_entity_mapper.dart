import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/features/employees/data/workforce_json_parser.dart';
import 'package:shiftly/features/invitations/domain/repositories/invitation_repository.dart';
import 'package:shiftly/features/workspaces/domain/repositories/workspace_repository.dart';

WorkspaceRecord parseWorkspaceRecord(Map<String, Object?> json) =>
    WorkspaceRecord(
      id: readString(json, 'id'),
      name: readString(json, 'name'),
      code: readString(json, 'code'),
      timezone: readString(json, 'timezone'),
      role: parseWorkspaceRole(json['role']),
      status: switch (json['status']) {
        'ACTIVE' => WorkspaceAccessStatus.active,
        'INVITED' => WorkspaceAccessStatus.invited,
        'SUSPENDED' => WorkspaceAccessStatus.suspended,
        _ => WorkspaceAccessStatus.unknown,
      },
    );

WorkspaceRecord parseAcceptedWorkspace(Object? data) {
  final body = asJsonMap(data), membership = asJsonMap(body['membership']);
  return parseWorkspaceRecord(<String, Object?>{
    ...asJsonMap(body['workspace']),
    'role': membership['role'],
    'status': membership['status'],
  });
}

Employee parseEmployee(Map<String, Object?> json) => Employee(
  id: readString(json, 'id'),
  profileId: readString(json, 'profileId'),
  fullName: optionalString(json['fullName']),
  phone: optionalString(json['phone']),
  email: optionalString(json['email']),
  jobTitle: optionalString(json['jobTitle']),
  location: null,
  shift: null,
  startDate: optionalDate(json['joinedAt']),
  employmentStatus: switch (json['status']) {
    'ACTIVE' => EmploymentStatus.active,
    'SUSPENDED' => EmploymentStatus.suspended,
    _ => EmploymentStatus.unknown,
  },
  role: switch (json['role']) {
    'EMPLOYEE' => EmployeeRole.employee,
    'MANAGER' => EmployeeRole.manager,
    _ => EmployeeRole.unknown,
  },
  avatarUrl: optionalString(json['avatarUrl']),
  monthlySalary: (json['monthlySalary'] as num?)?.toDouble(),
  hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
  payrollWorkDays: switch (json['payrollWorkDays']) {
    final int count when count >= 1 && count <= 31 => count,
    _ => 26,
  },
  createdAt: requiredDate(json, 'createdAt'),
  updatedAt: requiredDate(json, 'updatedAt'),
);

WorkspaceInvitation parseManagerInvitation(Map<String, Object?> json) =>
    WorkspaceInvitation(
      id: readString(json, 'id'),
      workspaceId: readString(json, 'workspaceId'),
      email: optionalString(json['email']),
      jobTitle: optionalString(json['jobTitle']),
      role: parseWorkspaceRole(json['role']),
      status: parseInvitationStatus(json['status']),
      expiresAt: requiredDate(json, 'expiresAt'),
      acceptedAt: optionalDate(json['acceptedAt']),
      revokedAt: optionalDate(json['revokedAt']),
      createdAt: requiredDate(json, 'createdAt'),
      updatedAt: requiredDate(json, 'updatedAt'),
      inviteToken: optionalString(json['inviteToken']),
    );
