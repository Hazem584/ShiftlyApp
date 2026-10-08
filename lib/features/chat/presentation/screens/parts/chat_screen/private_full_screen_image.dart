part of '../../chat_screen.dart';

class _FullScreenImage extends StatelessWidget {
  const _FullScreenImage({
    this.url,
    this.file,
    required this.heroTag,
    this.cache,
    this.scope,
  });
  final ChatMediaCache? cache;
  final ChatCacheScope? scope;
  final Uri? url;
  final File? file;
  final String heroTag;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      foregroundColor: Colors.white,
      backgroundColor: Colors.black,
      title: const Text('Image'),
    ),
    body: cache == null
        ? _image()
        : ValueListenableBuilder<int>(
            valueListenable: cache!.storage.changes,
            builder: (_, _, _) =>
                scope != null && cache!.storage.authorized(scope!)
                ? _image()
                : const Center(
                    child: Text(
                      'Chat access unavailable.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
          ),
  );
  Widget _image() => Center(
    child: Hero(
      tag: heroTag,
      child: InteractiveViewer(
        minScale: 0.8,
        maxScale: 5,
        child: file != null
            ? Image.file(file!, fit: BoxFit.contain)
            : Image.network(
                url!.toString(),
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
      ),
    ),
  );
}
