import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/collaboration_appearance.dart';
import 'package:shiftly/core/widgets/collaboration_session_boundary.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_document_content.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_page.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_tile.dart';

class ChatMediaDecision {
  const ChatMediaDecision({this.caption, this.reselect = false});
  final String? caption;
  final bool reselect;
}

class ChatMediaReviewScreen extends StatefulWidget {
  const ChatMediaReviewScreen({
    required this.kind,
    this.bytes,
    this.fileName,
    this.voicePath,
    this.durationMs,
    this.location,
    super.key,
  });
  final String kind;
  final Uint8List? bytes;
  final String? fileName, voicePath;
  final int? durationMs;
  final ChatLocation? location;
  @override
  State<ChatMediaReviewScreen> createState() => _ChatMediaReviewScreenState();
}

class _ChatMediaReviewScreenState extends State<ChatMediaReviewScreen> {
  final _caption = TextEditingController();
  AudioPlayer? _player;
  String? _error;
  bool _ready = false;
  @override
  void initState() {
    super.initState();
    if (widget.kind == 'VOICE') {
      _player = AudioPlayer();
      _prepare();
    }
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
    _caption.dispose();
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      CollaborationSessionBoundary(child: Builder(builder: _build));
  Widget _build(BuildContext context) => CollaborationAppearance(
    child: Builder(
      builder: (context) {
        final title = switch (widget.kind) {
          'IMAGE' => 'Image before sending',
          'VOICE' => 'Voice preview',
          'LOCATION' => 'Confirm location',
          _ => 'Document preview',
        };
        final action = switch (widget.kind) {
          'IMAGE' => 'Send image',
          'VOICE' => 'Send voice message',
          'LOCATION' => 'Send location',
          _ => 'Send document',
        };
        return EmployeePage(
          title: title,
          footer: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton(
                key: const Key('confirm-chat-media'),
                onPressed: () => Navigator.pop(
                  context,
                  ChatMediaDecision(caption: _caption.text.trim()),
                ),
                child: Text(context.tr(action)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(
                  context,
                  widget.kind == 'IMAGE' || widget.kind == 'DOCUMENT'
                      ? const ChatMediaDecision(reselect: true)
                      : null,
                ),
                child: Text(
                  context.tr(
                    widget.kind == 'IMAGE'
                        ? 'Choose a different image'
                        : widget.kind == 'DOCUMENT'
                        ? 'Choose a different document'
                        : widget.kind == 'VOICE'
                        ? 'Discard recording'
                        : 'Cancel',
                  ),
                ),
              ),
            ],
          ),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (widget.kind == 'IMAGE')
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.memory(
                    widget.bytes!,
                    height: 340,
                    fit: BoxFit.contain,
                  ),
                ),
              if (widget.kind == 'DOCUMENT') ...[
                EmployeeTile(
                  icon: Icons.description_outlined,
                  title: widget.fileName!,
                  subtitle:
                      '${(widget.bytes!.length / 1024).toStringAsFixed(1)} KB',
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 380,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ChatDocumentContent(
                      bytes: widget.bytes!,
                      fileName: widget.fileName!,
                      sourceId: 'local-preview',
                    ),
                  ),
                ),
              ],
              if (widget.kind == 'VOICE') ...[
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
                      tooltip: context.tr(
                        s.data?.playing == true ? 'Pause' : 'Play',
                      ),
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
                        s.data?.playing == true
                            ? Icons.pause
                            : Icons.play_arrow,
                      ),
                    ),
                  ),
                if (_error != null) Text(context.tr(_error!)),
              ],
              if (widget.location case final location?) ...[
                EmployeeTile(
                  icon: Icons.location_on_outlined,
                  title: context.tr('Check this location before sending.'),
                  subtitle:
                      '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}',
                ),
                const SizedBox(height: 16),
                Text(
                  context.tr(
                    'The location is a single point shared in this conversation.',
                  ),
                ),
              ],
              if (widget.kind == 'IMAGE' || widget.kind == 'LOCATION') ...[
                const SizedBox(height: 24),
                TextField(
                  key: const Key('chat-media-caption'),
                  controller: _caption,
                  maxLength: widget.kind == 'LOCATION' ? 120 : 1000,
                  maxLines: widget.kind == 'LOCATION' ? 1 : 3,
                  decoration: InputDecoration(
                    labelText: context.tr(
                      widget.kind == 'IMAGE'
                          ? 'Caption · Optional'
                          : 'Location name · Optional',
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    ),
  );
}
