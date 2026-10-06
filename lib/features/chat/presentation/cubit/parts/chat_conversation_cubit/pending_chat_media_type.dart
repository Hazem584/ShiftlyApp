part of '../../chat_conversation_cubit.dart';

enum PendingChatMediaType {
  image,
  voice;

  String get apiValue => switch (this) {
    PendingChatMediaType.image => 'IMAGE',
    PendingChatMediaType.voice => 'VOICE',
  };
}
