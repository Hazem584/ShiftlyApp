part of '../../chat_screen.dart';

class _RemoteImage extends StatefulWidget {
  const _RemoteImage({
    required this.repository,
    required this.workspaceId,
    required this.message,
  });
  final ChatRepository repository;
  final String workspaceId;
  final ChatMessage message;

  @override
  State<_RemoteImage> createState() => _RemoteImageState();
}
