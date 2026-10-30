import 'dart:typed_data';

abstract final class ChatDocumentValidation {
  static const maxBytes = 10 * 1024 * 1024;
  static const mimeTypes = {
    'pdf': 'application/pdf',
    'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'xls': 'application/vnd.ms-excel',
    'csv': 'text/csv',
    'txt': 'text/plain',
  };
  static String? mimeForName(String name) =>
      mimeTypes[name.split('.').last.toLowerCase()];
  static bool valid(Uint8List bytes, String name) =>
      bytes.isNotEmpty &&
      bytes.length <= maxBytes &&
      name.length <= 180 &&
      !RegExp(r'[\\/\x00-\x1f\x7f]').hasMatch(name) &&
      mimeForName(name) != null;
}
