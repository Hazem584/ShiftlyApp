import 'dart:convert';

const _redacted = '[redacted]';
const _maxInputLength = 32768;
const _maxDepth = 12;
const _privateKeys = {
  'passwd',
  'pwd',
  'passphrase',
  'authorization',
  'proxyauthorization',
  'apikey',
  'xapikey',
  'privatekey',
  'cookie',
  'setcookie',
  'accesskey',
  'accesskeyid',
  'clientassertion',
  'assertion',
  'tokens',
};

bool _privateKey(String key) {
  final normalized = key
      .replaceAllMapped(
        RegExp(r'\\u([a-f0-9]{4})', caseSensitive: false),
        (m) => String.fromCharCode(int.parse(m[1]!, radix: 16)),
      )
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]'), '');
  return _privateKeys.contains(normalized) ||
      normalized.contains('password') ||
      normalized.contains('secret') ||
      normalized.contains('credential') ||
      const [
        'token',
        'apikey',
        'privatekey',
        'authorization',
        'cookie',
      ].any(normalized.endsWith);
}

Object? _fields(Object? value, int depth) {
  if (depth >= _maxDepth) return _redacted;
  if (value is String) return _text(value, depth + 1);
  if (value is List) {
    return value.map((item) => _fields(item, depth + 1)).toList();
  }
  if (value is Map) {
    return {
      for (final entry in value.entries)
        entry.key.toString(): _privateKey(entry.key.toString())
            ? _redacted
            : _fields(entry.value, depth + 1),
    };
  }
  return value;
}

String _text(String value, int depth) {
  if (depth >= _maxDepth) return _redacted;
  if (value.length > _maxInputLength) return '[diagnostic omitted: too large]';
  try {
    // Sanitize parsed fields before serialization, including encoded JSON strings.
    return jsonEncode(_fields(jsonDecode(value), depth + 1));
  } on FormatException {
    // For ambiguous plain/embedded/broken JSON, discard the remainder after a
    // sensitive key instead of guessing the end of a quoted/multiline secret.
  }
  var safe = value;
  final assignments = RegExp(
    r'''(?:\\?["'])([A-Za-z][A-Za-z0-9_.\\ -]*)(?:\\?["'])\s*[:=]\s*|\b([A-Za-z][A-Za-z0-9_.-]*)\s*[:=]\s*''',
  );
  for (final match in assignments.allMatches(value)) {
    final key = match[1] ?? match[2]!;
    if (_privateKey(key)) {
      safe =
          '${value.substring(0, match.start)}${key.replaceAll(r'\', '')}=$_redacted';
      break;
    }
  }
  return safe
      .replaceAllMapped(
        RegExp(r'\b(Bearer|Basic)\s+\S+', caseSensitive: false),
        (m) => '${m[1]} $_redacted',
      )
      .replaceAll(
        RegExp(r'\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+'),
        '[token]',
      )
      .replaceAll(RegExp(r'https?://[^\s)]+'), '[url]')
      .replaceAll(
        RegExp(r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}', caseSensitive: false),
        '[email]',
      );
}

String redactDiagnostic(String value, int limit) {
  if (limit <= 0) return '';
  String safe;
  try {
    safe = _text(value, 0);
  } catch (_) {
    safe = '[diagnostic omitted]';
  }
  return safe.length > limit ? safe.substring(0, limit) : safe;
}
