part of '../../chat_screen.dart';

class _FullScreenImage extends StatelessWidget {
  const _FullScreenImage({required this.url, required this.heroTag});
  final Uri url;
  final String heroTag;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      foregroundColor: Colors.white,
      backgroundColor: Colors.black,
      title: const Text('Image'),
    ),
    body: Center(
      child: Hero(
        tag: heroTag,
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 5,
          child: Image.network(
            url.toString(),
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
    ),
  );
}
