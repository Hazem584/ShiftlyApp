part of '../../chat_models.dart';

class ChatMember extends Equatable {
  const ChatMember({
    required this.membershipId,
    this.profileId,
    this.fullName,
    this.email,
    this.avatarUrl,
    this.role,
  });

  final String membershipId;
  final String? profileId;
  final String? fullName;
  final String? email;
  final String? avatarUrl;
  final String? role;

  String get displayName => fullName ?? email ?? 'Workspace member';

  factory ChatMember.fromJson(Map<String, Object?> json) {
    final membership = json['membership'] is Map
        ? chatMap(json['membership'], 'membership')
        : json;
    final profile = membership['profile'] is Map
        ? chatMap(membership['profile'], 'member.profile')
        : const <String, Object?>{};
    return ChatMember(
      membershipId:
          chatOptionalUuid(membership['membershipId'] ?? membership['id']) ??
          (throw const FormatException('Invalid membershipId')),
      profileId: chatOptionalUuid(membership['profileId'] ?? profile['id']),
      fullName: _optionalText(membership['fullName'] ?? profile['fullName']),
      email: _optionalText(membership['email'] ?? profile['email']),
      avatarUrl: _optionalText(membership['avatarUrl'] ?? profile['avatarUrl']),
      role: _optionalText(membership['role']),
    );
  }

  @override
  List<Object?> get props => [
    membershipId,
    profileId,
    fullName,
    email,
    avatarUrl,
    role,
  ];
}
