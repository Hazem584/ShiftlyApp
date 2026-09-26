import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('rejects missing required values', () {
      expect(
        () => AppConfig.fromValues(
          supabaseUrl: '',
          supabasePublishableKey: '',
          apiBaseUrl: '',
        ),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('rejects insecure non-local URLs', () {
      expect(
        () => AppConfig.fromValues(
          supabaseUrl: 'http://project.supabase.co',
          supabasePublishableKey: 'publishable-key',
          apiBaseUrl: 'https://api.example.com/api/v1',
        ),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('rejects a duplicated API prefix', () {
      expect(
        () => AppConfig.fromValues(
          supabaseUrl: 'https://project.supabase.co',
          supabasePublishableKey: 'publishable-key',
          apiBaseUrl: 'https://api.example.com/api/v1/api/v1',
        ),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('accepts valid production configuration', () {
      final config = AppConfig.fromValues(
        supabaseUrl: 'https://project.supabase.co',
        supabasePublishableKey: 'publishable-key',
        apiBaseUrl: 'https://shiftly-backend-gamma.vercel.app/api/v1',
      );
      expect(config.apiBaseUrl.path, '/api/v1');
      expect(config.apiBaseUrl.scheme, 'https');
    });
  });
}
