import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/presentation/chat_playback_coordinator.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_conversation_cubit.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_location_card.dart';

class PendingMediaBubble extends StatelessWidget {
  const PendingMediaBubble({
    required this.pending,
    required this.onRetry,
    required this.onCancel,
    this.player,
    this.playback,
    this.cacheScope,
    super.key,
  });
  final PendingChatMessage pending;
  final AudioPlayer? player;
  final ChatPlaybackCoordinator? playback;
  final ChatCacheScope? cacheScope;
  final Future<void> Function(String) onRetry;
  final Future<void> Function(String) onCancel;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 320),
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pending.mediaType == PendingChatMediaType.text)
            Text(pending.text ?? '')
          else if (pending.mediaType == PendingChatMediaType.location)
            ChatLocationCard(location: pending.location!)
          else if (pending.mediaType == PendingChatMediaType.image)
            if (pending.previewBytes != null)
              Image.memory(
                pending.previewBytes!,
                height: 160,
                width: 260,
                cacheWidth: 720,
                fit: BoxFit.cover,
              )
            else if (pending.localPath != null)
              Image.file(
                File(pending.localPath!),
                height: 160,
                width: 260,
                cacheWidth: 720,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Text('Image preview unavailable'),
              )
            else
              const Row(
                children: [
                  Icon(Icons.image_outlined),
                  SizedBox(width: 8),
                  Text('Image'),
                ],
              )
          else
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  tooltip: 'Play prepared recording',
                  onPressed: pending.localPath == null || player == null
                      ? null
                      : () async {
                          if (playback != null && cacheScope != null) {
                            try {
                              await playback!.playPending(
                                cacheScope!,
                                File(pending.localPath!),
                                pending.clientMessageId,
                              );
                            } catch (_) {
                              /* Scoped media is unavailable. */
                            }
                            return;
                          }
                          final cache = context
                              .read<ChatGroupsCubit?>()
                              ?.mediaCache;
                          final file = File(pending.localPath!);
                          cache?.pin(file);
                          try {
                            await player!.setAudioSource(
                              AudioSource.uri(
                                Uri.file(pending.localPath!),
                                tag: pending.clientMessageId,
                              ),
                            );
                            await player!.play();
                          } catch (_) {
                            /* A scoped purge may interrupt pending playback. */
                          } finally {
                            cache?.unpin(file);
                          }
                        },
                ),
                const SizedBox(width: 8),
                const Expanded(child: Text('Voice message')),
                if (pending.durationMs != null) ...[
                  const SizedBox(width: 8),
                  Text(_durationLabel(pending.durationMs!)),
                ],
              ],
            ),
          const SizedBox(height: 8),
          if (const [
            ChatUploadState.preparing,
            ChatUploadState.uploading,
            ChatUploadState.finalizing,
            ChatUploadState.sending,
          ].contains(pending.status))
            LinearProgressIndicator(
              value: pending.status == ChatUploadState.preparing
                  ? null
                  : pending.progress.clamp(0, 1),
            ),
          Text(switch (pending.status) {
            ChatUploadState.queued => 'Queued',
            ChatUploadState.sending => 'Sending',
            ChatUploadState.uncertain =>
              'Confirmation unavailable — retry safely',
            ChatUploadState.preparing => 'Preparing…',
            ChatUploadState.uploading => 'Uploading…',
            ChatUploadState.finalizing => 'Sending…',
            ChatUploadState.sent => 'Sent',
            ChatUploadState.failed =>
              pending.failure?.message ?? 'Upload failed',
            ChatUploadState.cancelled => 'Cancelled',
          }),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (pending.status == ChatUploadState.failed ||
                  pending.status == ChatUploadState.uncertain)
                TextButton(
                  onPressed: () => onRetry(pending.clientMessageId),
                  child: Text(context.tr('Retry')),
                ),
              if (pending.canCancel)
                TextButton(
                  onPressed: () => onCancel(pending.clientMessageId),
                  child: Text(context.tr('Cancel')),
                ),
            ],
          ),
        ],
      ),
    ),
  );

  String _durationLabel(int durationMs) {
    final duration = Duration(milliseconds: durationMs);
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
