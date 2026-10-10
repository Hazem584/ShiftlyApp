import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shiftly/core/storage/platform_file.dart';

/// Memory decoding works on both native platforms and browsers.
class LocalMediaImage extends StatefulWidget {
  const LocalMediaImage(
    this.file, {
    super.key,
    this.fit,
    this.height,
    this.width,
    this.cacheWidth,
    this.errorBuilder,
  });
  final ChatLocalFile file;
  final BoxFit? fit;
  final double? height;
  final double? width;
  final int? cacheWidth;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  State<LocalMediaImage> createState() => _LocalMediaImageState();
}

class _LocalMediaImageState extends State<LocalMediaImage> {
  late Future<Uint8List> _bytes = widget.file.readAsBytes();
  @override
  void didUpdateWidget(LocalMediaImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.path != widget.file.path) {
      _bytes = widget.file.readAsBytes();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
    future: _bytes,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return widget.errorBuilder?.call(
              context,
              snapshot.error!,
              snapshot.stackTrace,
            ) ??
            const Icon(Icons.broken_image_outlined);
      }
      if (!snapshot.hasData) {
        return SizedBox(
          height: widget.height ?? 140,
          width: widget.width ?? 220,
          child: const Center(child: CircularProgressIndicator()),
        );
      }
      return Image.memory(
        snapshot.data!,
        fit: widget.fit,
        height: widget.height,
        width: widget.width,
        cacheWidth: widget.cacheWidth,
        errorBuilder: widget.errorBuilder,
      );
    },
  );
}
