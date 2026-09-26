class AppConfigException implements Exception {
  const AppConfigException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AppConfig {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.apiBaseUrl,
  });

  final Uri supabaseUrl;
  final String supabasePublishableKey;
  final Uri apiBaseUrl;

  factory AppConfig.fromEnvironment() => AppConfig.fromValues(
    supabaseUrl: const String.fromEnvironment('SUPABASE_URL'),
    supabasePublishableKey: const String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    ),
    apiBaseUrl: const String.fromEnvironment('SHIFTLY_API_BASE_URL'),
  );

  factory AppConfig.fromValues({
    required String supabaseUrl,
    required String supabasePublishableKey,
    required String apiBaseUrl,
  }) {
    if (supabaseUrl.trim().isEmpty ||
        supabasePublishableKey.trim().isEmpty ||
        apiBaseUrl.trim().isEmpty) {
      throw const AppConfigException(
        'Missing required configuration. Define SUPABASE_URL, '
        'SUPABASE_PUBLISHABLE_KEY, and SHIFTLY_API_BASE_URL.',
      );
    }
    final parsedSupabase = _validatedUri(
      supabaseUrl,
      name: 'SUPABASE_URL',
      allowLocalHttp: false,
    );
    final parsedApi = _validatedUri(
      apiBaseUrl,
      name: 'SHIFTLY_API_BASE_URL',
      allowLocalHttp: true,
    );
    final segments = parsedApi.pathSegments.where((part) => part.isNotEmpty);
    if (segments.join('/') != 'api/v1') {
      throw const AppConfigException(
        'SHIFTLY_API_BASE_URL must end with exactly /api/v1 and must not '
        'contain a duplicated API prefix.',
      );
    }
    return AppConfig(
      supabaseUrl: parsedSupabase,
      supabasePublishableKey: supabasePublishableKey.trim(),
      apiBaseUrl: parsedApi.replace(path: '/api/v1'),
    );
  }

  static Uri _validatedUri(
    String value, {
    required String name,
    required bool allowLocalHttp,
  }) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw AppConfigException('$name must be a valid absolute URL.');
    }
    final local =
        uri.host == 'localhost' ||
        uri.host == '127.0.0.1' ||
        uri.host == '10.0.2.2';
    if (uri.scheme != 'https' && !(allowLocalHttp && local)) {
      throw AppConfigException('$name must use HTTPS.');
    }
    if (uri.query.isNotEmpty || uri.fragment.isNotEmpty) {
      throw AppConfigException('$name must not contain a query or fragment.');
    }
    return uri;
  }
}
