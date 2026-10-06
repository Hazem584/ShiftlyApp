part of '../../chat_screen.dart';

class _VoiceMessage extends StatefulWidget {
  const _VoiceMessage({
    required this.repository,
    required this.workspaceId,
    required this.message,
    required this.player,
  });
  final ChatRepository repository;
  final String workspaceId;
  final ChatMessage message;
  final AudioPlayer player;

  @override
  State<_VoiceMessage> createState() => _VoiceMessageState();
}
