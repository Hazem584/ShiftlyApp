part of '../../chat_screen.dart';

class _FullScreenImage extends StatefulWidget {
  const _FullScreenImage({
    this.url,
    this.file,
    required this.heroTag,
    this.cache,
    this.scope,
    this.saveImage,
  });
  final ChatMediaCache? cache;
  final ChatCacheScope? scope;
  final Uri? url;
  final File? file;
  final String heroTag;
  final Future<void> Function()? saveImage;

  @override
  State<_FullScreenImage> createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<_FullScreenImage> {
  bool _saving = false;
  ChatMediaCache? get cache => widget.cache;
  ChatCacheScope? get scope => widget.scope;
  Uri? get url => widget.url;
  File? get file => widget.file;
  String get heroTag => widget.heroTag;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      foregroundColor: Colors.white,
      backgroundColor: Colors.black,
      title: const Text('Image'),
      actions: [
        if (!kIsWeb &&
            const [
              TargetPlatform.android,
              TargetPlatform.iOS,
            ].contains(defaultTargetPlatform) &&
            widget.saveImage != null)
          IconButton(
            key: const Key('save-chat-image'),
            tooltip: 'Save to photos',
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download_rounded),
          ),
      ],
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

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await widget.saveImage!();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Image saved to photos.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is PlatformException &&
                      error.code == 'PHOTO_PERMISSION_DENIED'
                  ? 'Allow photo access in your phone settings to save images.'
                  : 'Could not save this image. Check your connection and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

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
