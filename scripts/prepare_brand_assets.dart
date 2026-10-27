import 'dart:io';

import 'package:image/image.dart' as img;

/// Resize the approved source without redrawing it. Run from the project root.
void main() {
  final source = img.decodePng(
    File('assets/images/shiftly-mark.png').readAsBytesSync(),
  );
  if (source == null) throw StateError('Invalid Shiftly brand source');
  void write(String path, int size, {int? canvasSize}) {
    final mark = img.copyResize(
      source,
      width: size,
      height: size,
      interpolation: img.Interpolation.average,
    );
    final output = canvasSize == null
        ? mark
        : img.Image(width: canvasSize, height: canvasSize, numChannels: 4);
    if (canvasSize != null) {
      img.compositeImage(
        output,
        mark,
        dstX: (canvasSize - size) ~/ 2,
        dstY: (canvasSize - size) ~/ 2,
      );
    }
    File(path)
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(img.encodePng(output));
  }

  for (final entry in {
    'mdpi': 1.0,
    'hdpi': 1.5,
    'xhdpi': 2.0,
    'xxhdpi': 3.0,
    'xxxhdpi': 4.0,
  }.entries) {
    write(
      'android/app/src/main/res/drawable-${entry.key}/shiftly_splash.png',
      (156 * entry.value).round(),
    );
    write(
      'android/app/src/main/res/drawable-${entry.key}/shiftly_splash_android12.png',
      (192 * entry.value).round(),
      canvasSize: (288 * entry.value).round(),
    );
  }
  for (final scale in [1, 2, 3]) {
    write(
      'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage${scale == 1 ? '' : '@${scale}x'}.png',
      156 * scale,
    );
  }
  // The web loader uses the transparent mark, not an opaque launcher tile.
  write('web/brand/shiftly-mark.png', 312);
  stdout.writeln('Prepared native and web splash images.');
}
