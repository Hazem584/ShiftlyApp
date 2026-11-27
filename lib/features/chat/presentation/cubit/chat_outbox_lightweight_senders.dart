import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/entities/chat_outbox_operation.dart';

import 'chat_message_uuid.dart';
import 'chat_outbox_accepter.dart';
import 'chat_outbox_controller.dart';

Future<bool> sendOutboxText(
  ChatOutboxController c,
  String value, {
  String? replyToMessageId,
}) async {
  final text = value.trim();
  if (text.isEmpty || text.length > 4000) return false;
  return acceptChatOutboxOperation(
    c,
    ChatOutboxOperation(
      id: chatMessageUuid(),
      type: 'TEXT',
      text: text,
      replyToMessageId: replyToMessageId,
      createdAt: DateTime.now().toUtc(),
    ),
  );
}

Future<bool> sendOutboxLocation(ChatOutboxController c, ChatLocation loc) =>
    !loc.isValid
    ? Future.value(false)
    : acceptChatOutboxOperation(
        c,
        ChatOutboxOperation(
          id: chatMessageUuid(),
          type: 'LOCATION',
          location: loc,
          createdAt: DateTime.now().toUtc(),
        ),
      );
