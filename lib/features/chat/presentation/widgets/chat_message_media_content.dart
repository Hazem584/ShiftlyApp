import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/presentation/chat_playback_coordinator.dart';

import 'chat_document_message.dart';
import 'chat_location_card.dart';
import 'chat_remote_image.dart';
import 'chat_voice_message.dart';

Widget buildChatMessageContent(
  BuildContext context, {
  required ChatMessage message,
  required ChatRepository repository,
  required String workspaceId,
  required AudioPlayer player,
  required ChatPlaybackCoordinator? playback,
}) => switch (message.type) {
  'TEXT' => Text(message.text ?? ''),
  'DOCUMENT' => ChatDocumentMessage(
    message: message,
    repository: repository,
    workspaceId: workspaceId,
  ),
  'IMAGE' => ChatRemoteImage(
    repository: repository,
    workspaceId: workspaceId,
    message: message,
  ),
  'VOICE' => ChatVoiceMessage(
    repository: repository,
    workspaceId: workspaceId,
    message: message,
    player: player,
    playback: playback,
  ),
  'LOCATION' => ChatLocationCard(location: message.location),
  _ => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.help_outline, size: 18),
      const SizedBox(width: 8),
      Text(context.tr('Unsupported message')),
    ],
  ),
};
