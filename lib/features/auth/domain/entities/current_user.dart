import 'package:shiftly/features/auth/domain/entities/current_user_parsers.dart';
import 'package:shiftly/features/auth/domain/entities/workspace_membership.dart';

export 'package:shiftly/features/auth/domain/entities/current_user_parsers.dart';
export 'package:shiftly/features/auth/domain/entities/membership_status.dart';
export 'package:shiftly/features/auth/domain/entities/workspace.dart';
export 'package:shiftly/features/auth/domain/entities/workspace_membership.dart';
export 'package:shiftly/features/auth/domain/entities/workspace_role.dart';

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
      id: currentUserRequiredString(json, 'id'),
      email: currentUserOptionalString(json['email']),
      fullName: currentUserOptionalString(json['fullName']),
      phone: currentUserOptionalString(json['phone']),
      avatarUrl: currentUserOptionalString(json['avatarUrl']),
      createdAt: currentUserRequiredDate(json, 'createdAt'),
      updatedAt: currentUserRequiredDate(json, 'updatedAt'),
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

  CurrentUser copyWithProfile({
    required String? email,
    required String? fullName,
    required String? phone,
    required String? avatarUrl,
    DateTime? updatedAt,
  }) => CurrentUser(
    id: id,
    email: email,
    fullName: fullName,
    phone: phone,
    avatarUrl: avatarUrl,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    memberships: memberships,
  );
}
