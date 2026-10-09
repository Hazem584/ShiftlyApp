import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/presentation/chat_playback_coordinator.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';

class ChatVoiceMessage extends StatefulWidget {
  const ChatVoiceMessage({
    super.key,
    required this.repository,
    required this.workspaceId,
    required this.message,
    required this.player,
    this.playback,
  });
  final ChatRepository repository;
  final String workspaceId;
  final ChatMessage message;
  final AudioPlayer player;
  final ChatPlaybackCoordinator? playback;

  @override
  State<ChatVoiceMessage> createState() => _VoiceMessageState();
}

class _VoiceMessageState extends State<ChatVoiceMessage> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) => StreamBuilder<PlayerState>(
    stream: widget.player.playerStateStream,
    builder: (context, state) {
      final active =
          widget.player.audioSource != null &&
          widget.player.sequenceState.currentSource?.tag == widget.message.id;
      final playing = active && widget.player.playing;
      final buffering =
          active &&
          (state.data?.processingState == ProcessingState.loading ||
              state.data?.processingState == ProcessingState.buffering);
      final duration = widget.message.attachment?.durationMs ?? 0;
      return SizedBox(
        width: 230,
        child: Row(
          children: [
            IconButton.filledTonal(
              tooltip: playing ? 'Pause voice message' : 'Play voice message',
              onPressed: _loading || buffering
                  ? null
                  : () => _toggle(active, playing),
              icon: _loading || buffering
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      state.data?.processingState ==
                                  ProcessingState.completed &&
                              active
                          ? Icons.replay
                          : playing
                          ? Icons.pause
                          : Icons.play_arrow,
                    ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StreamBuilder<Duration>(
                stream: widget.player.positionStream,
                builder: (_, position) {
                  final shown = active
                      ? position.data?.inMilliseconds
                                .clamp(0, duration)
                                .toInt() ??
                            0
                      : 0;
                  final progress = duration == 0 ? 0.0 : shown / duration;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14,
                          ),
                        ),
                        child: Slider(
                          value: progress.clamp(0, 1),
                          onChanged: active && duration > 0
                              ? (value) => widget.player.seek(
                                  Duration(
                                    milliseconds: (value * duration).round(),
                                  ),
                                )
                              : null,
                        ),
                      ),
                      Text(
                        '${_duration(shown)} / ${_duration(duration)}',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );

  Future<void> _toggle(bool active, bool playing) async {
    try {
      if (active && playing) {
        if (widget.playback != null) {
          widget.playback!.pause();
          return;
        }
        await widget.player.pause();
        return;
      }
      setState(() => _loading = true);
      final groups = context.read<ChatGroupsCubit>();
      final cache = groups.mediaCache;
      final scope = groups.scope;
      if (cache != null && scope != null) {
        final key = ChatCacheScope.fromSession(scope, widget.message.groupId);
        if (widget.playback != null) {
          await widget.playback!.play(key, widget.message, widget.repository);
          return;
        }
        final file = await cache.resolve(
          key,
          widget.message,
          widget.repository,
        );
        if (!mounted || !cache.storage.authorized(key)) return;
        cache.pin(file);
        try {
          await widget.player.setAudioSource(
            AudioSource.uri(Uri.file(file.path), tag: widget.message.id),
          );
          if (!mounted || !cache.storage.authorized(key)) {
            await widget.player.stop();
            return;
          }
          setState(() => _loading = false);
          await widget.player.play();
        } finally {
          cache.unpin(file);
        }
        return;
      }
      final media = await widget.repository.mediaUrl(
        widget.workspaceId,
        widget.message.groupId,
        widget.message.id,
      );
      await widget.player.setAudioSource(
        AudioSource.uri(media.url, tag: widget.message.id),
      );
      if (!mounted) return;
      setState(() => _loading = false);
      await widget.player.play();
    } catch (_) {
      Fluttertoast.showToast(msg: 'This voice message is unavailable.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _duration(int milliseconds) {
    final seconds = (milliseconds / 1000).floor();
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}
