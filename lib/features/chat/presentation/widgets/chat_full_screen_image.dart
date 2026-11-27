import 'package:flutter/foundation.dart'
    show kIsWeb, TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/storage/platform_file.dart';
import 'package:shiftly/core/widgets/local_media_image.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_media_store.dart';

import 'chat_image_save_button.dart';

class ChatFullScreenImage extends StatefulWidget {
  const ChatFullScreenImage({
    super.key,
    this.url,
    this.file,
    required this.heroTag,
    this.cache,
    this.scope,
    this.saveImage,
  });
  final ChatMediaStore? cache;
  final ChatCacheScope? scope;
  final Uri? url;
  final ChatLocalFile? file;
  final String heroTag;
  final Future<void> Function()? saveImage;

  @override
  State<ChatFullScreenImage> createState() => _FullScreenImageState();
}

class _FullScreenImageState extends State<ChatFullScreenImage> {
  ChatMediaStore? get cache => widget.cache;
  ChatCacheScope? get scope => widget.scope;
  Uri? get url => widget.url;
  ChatLocalFile? get file => widget.file;
  String get heroTag => widget.heroTag;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      foregroundColor: Colors.white,
      backgroundColor: Colors.black,
      title: Text(context.tr('Image')),
      actions: [
        if ((kIsWeb ||
                const [
                  TargetPlatform.android,
                  TargetPlatform.iOS,
                ].contains(defaultTargetPlatform)) &&
            widget.saveImage != null)
          ChatImageSaveButton(saveImage: widget.saveImage!),
      ],
    ),
    body: cache == null
        ? _image()
        : StreamBuilder<int>(
            stream: cache!.storage.revisions,
            builder: (_, _) =>
                scope != null && cache!.storage.authorized(scope!)
                ? _image()
                : Center(
                    child: Text(
                      context.tr('Chat access unavailable.'),
                      style: const TextStyle(color: Colors.white),
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
            ? LocalMediaImage(file!, fit: BoxFit.contain)
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
