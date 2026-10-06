part of '../../chat_screen.dart';

class _RemoteImageState extends State<_RemoteImage> {
  late Future<ChatMediaUrl> _media;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  void _resolve() {
    _media = widget.repository.mediaUrl(
      widget.workspaceId,
      widget.message.groupId,
      widget.message.id,
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<ChatMediaUrl>(
    future: _media,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return SizedBox(
          width: 220,
          height: 140,
          child: Center(
            child: TextButton.icon(
              onPressed: () => setState(_resolve),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry image'),
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const SizedBox(
          width: 220,
          height: 140,
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final url = snapshot.data!.url;
      final heroTag = 'chat-image-${widget.message.id}';
      return InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _FullScreenImage(url: url, heroTag: heroTag),
          ),
        ),
        borderRadius: BorderRadius.circular(14),
        child: Hero(
          tag: heroTag,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320, maxHeight: 360),
              child: Image.network(
                url.toString(),
                fit: BoxFit.cover,
                cacheWidth: 960,
                errorBuilder: (_, _, _) => SizedBox(
                  width: 220,
                  height: 140,
                  child: Center(
                    child: TextButton.icon(
                      onPressed: () => setState(_resolve),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry image'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
