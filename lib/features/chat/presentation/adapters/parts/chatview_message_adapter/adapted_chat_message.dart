part of '../../chatview_message_adapter.dart';

class AdaptedChatMessage {
  const AdaptedChatMessage({required this.message, required this.kind});

  final chatview.Message message;
  final ShiftlyChatPresentationKind kind;
}
