import 'package:equatable/equatable.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models_parsers.dart';

class ChatReaction extends Equatable {
  const ChatReaction({required this.emoji, required this.membershipId});
  static const choices = ['👍', '❤️', '😂', '😮', '😢', '🙏'];
  final String emoji, membershipId;
  factory ChatReaction.fromJson(Map<String, Object?> json) {
    final emoji = chatModelsText(json, 'emoji');
    if (!choices.contains(emoji)) {
      throw const FormatException('Invalid reaction');
    }
    return ChatReaction(
      emoji: emoji,
      membershipId: chatUuid(json, 'membershipId'),
    );
  }
  Map<String, Object?> toJson() => {
    'emoji': emoji,
    'membershipId': membershipId,
  };
  @override
  List<Object?> get props => [emoji, membershipId];
}
