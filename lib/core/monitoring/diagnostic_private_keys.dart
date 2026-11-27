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

bool isPrivateDiagnosticKey(String key) {
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
