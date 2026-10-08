part of '../../chat_screen.dart';

class _RemoteImageState extends State<_RemoteImage> {
  late Future<Object> _media;
  File? _pinned;
  ChatMediaCache? _cache;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  void _resolve() {
    final groups = context.read<ChatGroupsCubit>();
    final cache = groups.mediaCache;
    _cache = cache;
    final scope = groups.scope;
    if (cache != null && scope != null) {
      _media = cache
          .resolve(
            ChatCacheScope.fromSession(scope, widget.message.groupId),
            widget.message,
            widget.repository,
          )
          .then((file) {
            if (mounted) {
              if (_pinned case final former?) cache.unpin(former);
              _pinned = file;
              cache.pin(file);
            }
            return file;
          });
      return;
    }
    _media = widget.repository.mediaUrl(
      widget.workspaceId,
      widget.message.groupId,
      widget.message.id,
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Object>(
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
      final media = snapshot.data!;
      final file = media is File ? media : null;
      final url = media is ChatMediaUrl ? media.url : null;
      final heroTag = 'chat-image-${widget.message.id}';
      return InkWell(
        onTap: () async {
          final groups = context.read<ChatGroupsCubit>();
          final cache = groups.mediaCache;
          final session = groups.scope;
          if (file != null) cache?.pin(file);
          try {
            await Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => _FullScreenImage(
                  url: url,
                  file: file,
                  heroTag: heroTag,
                  cache: cache,
                  scope: session == null
                      ? null
                      : ChatCacheScope.fromSession(
                          session,
                          widget.message.groupId,
                        ),
                ),
              ),
            );
          } finally {
            if (file != null) cache?.unpin(file);
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Hero(
          tag: heroTag,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320, maxHeight: 360),
              child: file != null
                  ? Image.file(
                      file,
                      fit: BoxFit.cover,
                      cacheWidth: 960,
                      errorBuilder: (_, _, _) => TextButton(
                        onPressed: () => setState(_resolve),
                        child: const Text('Retry image'),
                      ),
                    )
                  : Image.network(
                      url!.toString(),
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
  @override
  void dispose() {
    final file = _pinned;
    if (file != null) _cache?.unpin(file);
    super.dispose();
  }
}
