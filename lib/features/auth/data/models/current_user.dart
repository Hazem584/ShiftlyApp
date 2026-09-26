enum WorkspaceRole {
  manager,
  employee,
  unknown;

  static WorkspaceRole parse(Object? value) => switch (value) {
    'MANAGER' => manager,
    'EMPLOYEE' => employee,
    _ => unknown,
  };
}

enum MembershipStatus {
  invited,
  active,
  suspended,
  unknown;

  static MembershipStatus parse(Object? value) => switch (value) {
    'INVITED' => invited,
    'ACTIVE' => active,
    'SUSPENDED' => suspended,
    _ => unknown,
  };
}

class Workspace {
  const Workspace({
    required this.id,
    required this.name,
    required this.code,
    required this.timezone,
  });

  final String id;
  final String name;
  final String code;
  final String timezone;

  factory Workspace.fromJson(Map<String, Object?> json) => Workspace(
    id: _requiredString(json, 'id'),
    name: _requiredString(json, 'name'),
    code: _requiredString(json, 'code'),
    timezone: _requiredString(json, 'timezone'),
  );
}

class WorkspaceMembership {
  const WorkspaceMembership({
    required this.role,
    required this.status,
    required this.workspace,
    this.jobTitle,
    this.joinedAt,
  });

  final WorkspaceRole role;
  final MembershipStatus status;
  final String? jobTitle;
  final DateTime? joinedAt;
  final Workspace workspace;

  factory WorkspaceMembership.fromJson(Map<String, Object?> json) {
    final workspace = json['workspace'];
    if (workspace is! Map) throw const FormatException('Invalid workspace');
    return WorkspaceMembership(
      role: WorkspaceRole.parse(json['role']),
      status: MembershipStatus.parse(json['status']),
      jobTitle: _optionalString(json['jobTitle']),
      joinedAt: _optionalDate(json['joinedAt']),
      workspace: Workspace.fromJson(Map<String, Object?>.from(workspace)),
    );
  }
}

class CurrentUser {
  const CurrentUser({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.memberships,
    this.email,
    this.fullName,
    this.phone,
    this.avatarUrl,
  });

  final String id;
  final String? email;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<WorkspaceMembership> memberships;

  factory CurrentUser.fromJson(Map<String, Object?> json) {
    final rawMemberships = json['memberships'];
    if (rawMemberships is! List) {
      throw const FormatException('Invalid memberships');
    }
    return CurrentUser(
      id: _requiredString(json, 'id'),
      email: _optionalString(json['email']),
      fullName: _optionalString(json['fullName']),
      phone: _optionalString(json['phone']),
      avatarUrl: _optionalString(json['avatarUrl']),
      createdAt: _requiredDate(json, 'createdAt'),
      updatedAt: _requiredDate(json, 'updatedAt'),
      memberships: rawMemberships
          .map((item) {
            if (item is! Map) throw const FormatException('Invalid membership');
            return WorkspaceMembership.fromJson(
              Map<String, Object?>.from(item),
            );
          })
          .toList(growable: false),
    );
  }
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) throw FormatException('Invalid $key');
  return value;
}

String? _optionalString(Object? value) =>
    value is String && value.isNotEmpty ? value : null;

DateTime _requiredDate(Map<String, Object?> json, String key) {
  final value = json[key];
  final parsed = value is String ? DateTime.tryParse(value) : null;
  if (parsed == null) throw FormatException('Invalid $key');
  return parsed.toUtc();
}

DateTime? _optionalDate(Object? value) {
  if (value == null) return null;
  final parsed = value is String ? DateTime.tryParse(value) : null;
  if (parsed == null) throw const FormatException('Invalid date');
  return parsed.toUtc();
}
