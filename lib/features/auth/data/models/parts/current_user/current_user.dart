part of '../../current_user.dart';

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
