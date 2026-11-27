import 'dart:convert';
import 'dart:typed_data';

Uri browserRecordingUri(Uint8List bytes) {
  final webm = bytes.length >= 4 && bytes[0] == 0x1a && bytes[1] == 0x45;
  final ogg =
      bytes.length >= 4 &&
      ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'OggS';
  return Uri.dataFromBytes(
    bytes,
    mimeType: webm
        ? 'audio/webm'
        : ogg
        ? 'audio/ogg'
        : 'audio/mp4',
  );
}
