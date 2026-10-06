part of '../../chat_screen.dart';

class _VoiceMessageState extends State<_VoiceMessage> {
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
        await widget.player.pause();
        return;
      }
      if (active &&
          widget.player.processingState != ProcessingState.completed) {
        await widget.player.play();
        return;
      }
      setState(() => _loading = true);
      final media = await widget.repository.mediaUrl(
        widget.workspaceId,
        widget.message.groupId,
        widget.message.id,
      );
      await widget.player.setAudioSource(
        AudioSource.uri(media.url, tag: widget.message.id),
      );
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
