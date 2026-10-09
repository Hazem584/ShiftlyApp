import 'package:equatable/equatable.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models_parsers.dart';

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
      fullName: chatModelsOptionalText(
        membership['fullName'] ?? profile['fullName'],
      ),
      email: chatModelsOptionalText(membership['email'] ?? profile['email']),
      avatarUrl: chatModelsOptionalText(
        membership['avatarUrl'] ?? profile['avatarUrl'],
      ),
      role: chatModelsOptionalText(membership['role']),
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
