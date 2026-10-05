import 'package:chatview/chatview.dart' as chatview;
import 'package:flutter/material.dart';
import 'package:shiftly/features/chat/data/chat_models.dart';

enum ShiftlyChatPresentationKind { text, image, voice, location, unknown }

class AdaptedChatMessage {
  const AdaptedChatMessage({required this.message, required this.kind});

  final chatview.Message message;
  final ShiftlyChatPresentationKind kind;
}

abstract final class ChatViewMessageAdapter {
  static AdaptedChatMessage fromShiftly(ChatMessage source) {
    final kind = switch (source.type) {
      'TEXT' => ShiftlyChatPresentationKind.text,
      'IMAGE' => ShiftlyChatPresentationKind.image,
      'VOICE' => ShiftlyChatPresentationKind.voice,
      'LOCATION' => ShiftlyChatPresentationKind.location,
      _ => ShiftlyChatPresentationKind.unknown,
    };
    return AdaptedChatMessage(
      kind: kind,
      message: chatview.Message(
        id: source.id,
        message: source.text ?? source.type,
        createdAt: source.createdAt,
        sentBy: source.sender.membershipId,
        messageType: chatview.MessageType.custom,
        status: chatview.MessageStatus.pending,
      ),
    );
  }

  static chatview.ChatUser user(ChatSender sender) => chatview.ChatUser(
    id: sender.membershipId,
    name: sender.displayName,
    profilePhoto: sender.avatarUrl,
    networkImageErrorBuilder: (_, _, _) => const SizedBox.shrink(),
  );
}
