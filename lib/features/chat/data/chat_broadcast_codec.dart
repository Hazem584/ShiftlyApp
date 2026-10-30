import 'package:shiftly/features/chat/domain/entities/chat_models.dart';

abstract final class ChatBroadcastCodec {
  static ChatMessage decode(Map<String, dynamic> event, String groupId) {
    // Supabase onBroadcast delivers the event envelope, not just its payload.
    final json = chatMap(event['payload'] ?? event);
    if (json['groupId'] != groupId) {
      throw const FormatException('Cross-group broadcast');
    }
    return ChatMessage.fromJson(json);
  }
}
