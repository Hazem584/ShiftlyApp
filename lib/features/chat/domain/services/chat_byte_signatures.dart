import 'dart:typed_data';

bool matchesBytes(Uint8List bytes, List<int> signature) {
  return matchesBytesAt(bytes, 0, signature);
}

bool matchesBytesAt(Uint8List bytes, int offset, List<int> signature) {
  if (offset < 0 || bytes.length < offset + signature.length) return false;
  for (var index = 0; index < signature.length; index++) {
    if (bytes[offset + index] != signature[index]) return false;
  }
  return true;
}

int littleEndianUint32(Uint8List bytes, int offset) =>
    bytes[offset] |
    (bytes[offset + 1] << 8) |
    (bytes[offset + 2] << 16) |
    (bytes[offset + 3] << 24);

bool matchesAscii(Uint8List bytes, int offset, String value) {
  if (bytes.length < offset + value.length) return false;
  for (var index = 0; index < value.length; index++) {
    if (bytes[offset + index] != value.codeUnitAt(index)) return false;
  }
  return true;
}
