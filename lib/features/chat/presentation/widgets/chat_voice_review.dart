import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class ChatVoiceReview extends StatefulWidget {
  const ChatVoiceReview({this.voicePath, this.durationMs, super.key});

  final String? voicePath;
  final int? durationMs;

  @override
  State<ChatVoiceReview> createState() => _ChatVoiceReviewState();
}

class _ChatVoiceReviewState extends State<ChatVoiceReview>
    with AutomaticKeepAliveClientMixin<ChatVoiceReview> {
  AudioPlayer? _player;
  String? _error;
  bool _ready = false;
  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      if (kIsWeb) {
        await _player!.setUrl(widget.voicePath!);
      } else {
        await _player!.setFilePath(widget.voicePath!);
      }
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Voice preview is unavailable. You can still send the recording.',
        );
      }
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.graphic_eq, size: 80),
        const SizedBox(height: 28),
        Text(
          '${((widget.durationMs ?? 0) ~/ 60000).toString().padLeft(2, '0')}:${(((widget.durationMs ?? 0) ~/ 1000) % 60).toString().padLeft(2, '0')}',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        if (_player != null)
          StreamBuilder<PlayerState>(
            stream: _player!.playerStateStream,
            builder: (c, s) => IconButton.filledTonal(
              tooltip: context.tr(s.data?.playing == true ? 'Pause' : 'Play'),
              onPressed: _ready
                  ? () async {
                      if (_player!.playing) {
                        await _player!.pause();
                      } else {
                        if (_player!.processingState ==
                            ProcessingState.completed) {
                          await _player!.seek(Duration.zero);
                        }
                        _player!.play();
                      }
                    }
                  : null,
              icon: Icon(
                s.data?.playing == true ? Icons.pause : Icons.play_arrow,
              ),
            ),
          ),
        if (_error != null) Text(context.tr(_error!)),
      ],
    );
  }
}
