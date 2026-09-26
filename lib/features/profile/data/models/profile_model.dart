import 'package:shiftly/core/models/manager_profile.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';

class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
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

  factory ProfileModel.fromJson(Map<String, Object?> json) => ProfileModel(
    id: _requiredString(json, 'id'),
    email: _optionalString(json['email']),
    fullName: _optionalString(json['fullName']),
    phone: _optionalString(json['phone']),
    avatarUrl: _optionalString(json['avatarUrl']),
    createdAt: _requiredDate(json, 'createdAt'),
    updatedAt: _requiredDate(json, 'updatedAt'),
  );

  factory ProfileModel.fromCurrentUser(CurrentUser user) => ProfileModel(
    id: user.id,
    email: user.email,
    fullName: user.fullName,
    phone: user.phone,
    avatarUrl: user.avatarUrl,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt,
  );

  ManagerProfile toPresentation(WorkspaceMembership? membership) =>
      ManagerProfile(
        id: id,
        fullName: fullName ?? 'Shiftly user',
        role: switch (membership?.role) {
          WorkspaceRole.manager => membership?.jobTitle ?? 'Manager',
          WorkspaceRole.employee => membership?.jobTitle ?? 'Employee',
          _ => 'Team member',
        },
        email: email ?? 'Not provided',
        phone: phone ?? 'Not provided',
        workplace: membership?.workspace.name ?? 'No active workspace',
        avatarUrl: avatarUrl,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
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
