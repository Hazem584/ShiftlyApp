bool chatModelsValidStoragePath(Object? value) {
  if (value is! String ||
      value.trim() != value ||
      value.isEmpty ||
      value.startsWith('/') ||
      value.endsWith('/') ||
      value.contains(r'\')) {
    return false;
  }
  try {
    return value.split('/').every((segment) {
      final decoded = Uri.decodeComponent(segment);
      return decoded.isNotEmpty &&
          decoded != '.' &&
          decoded != '..' &&
          !decoded.contains('/') &&
          !decoded.contains(r'\');
    });
  } on FormatException {
    return false;
  }
}
