part of '../../chat_conversation_cubit.dart';

enum PendingChatMediaType {
  text,
  location,
  image,
  voice;

  String get apiValue => switch (this) {
    PendingChatMediaType.text => 'TEXT',
    PendingChatMediaType.location => 'LOCATION',
    PendingChatMediaType.image => 'IMAGE',
    PendingChatMediaType.voice => 'VOICE',
  };
}
