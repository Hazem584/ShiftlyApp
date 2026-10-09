import 'package:equatable/equatable.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models_parsers.dart';

class ChatSender extends Equatable {
  const ChatSender({
    required this.membershipId,
    this.profileId,
    this.fullName,
    this.avatarUrl,
  });

  final String membershipId;
  final String? profileId;
  final String? fullName;
  final String? avatarUrl;

  String get displayName => fullName ?? 'Workspace member';

  factory ChatSender.fromJson(Map<String, Object?> json) {
    final profile = json['profile'] is Map
        ? chatMap(json['profile'], 'sender.profile')
        : const <String, Object?>{};
    return ChatSender(
      membershipId:
          chatOptionalUuid(json['membershipId'] ?? json['id']) ??
          (throw const FormatException('Invalid membershipId')),
      profileId: chatOptionalUuid(json['profileId'] ?? profile['id']),
      fullName: chatModelsOptionalText(json['fullName'] ?? profile['fullName']),
      avatarUrl: chatModelsOptionalText(
        json['avatarUrl'] ?? profile['avatarUrl'],
      ),
    );
  }

  @override
  List<Object?> get props => [membershipId, profileId, fullName, avatarUrl];
}
