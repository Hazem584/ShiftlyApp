import 'dart:convert';
import 'dart:typed_data';

String previewCell(String value) =>
    value.length > 1000 ? value.substring(0, 1000) : value;
String decodePreviewText(Uint8List bytes) {
  if (bytes.length >= 2 &&
      ((bytes[0] == 255 && bytes[1] == 254) ||
          (bytes[0] == 254 && bytes[1] == 255))) {
    final little = bytes[0] == 255;
    return String.fromCharCodes([
      for (var i = 2; i + 1 < bytes.length; i += 2)
        little
            ? bytes[i] | (bytes[i + 1] << 8)
            : (bytes[i] << 8) | bytes[i + 1],
    ]);
  }
  return utf8
      .decode(bytes, allowMalformed: true)
      .replaceFirst(RegExp(r'^\uFEFF'), '');
}
