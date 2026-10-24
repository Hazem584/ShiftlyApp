import 'dart:convert';

export 'package:shiftly/features/auth/domain/entities/authentication_event.dart';
export 'package:shiftly/features/auth/domain/entities/authentication_event_type.dart';
export 'package:shiftly/features/auth/domain/entities/authentication_result.dart';

class AuthSession {
  const AuthSession({required this.accessToken});

  final String accessToken;

  String? get sessionId => _claim('session_id');
  String? get userId => _claim('sub');

  String? _claim(String name) {
    try {
      final parts = accessToken.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      return payload is Map && payload[name] is String
          ? payload[name] as String
          : null;
    } catch (_) {
      return null;
    }
  }

  // Identity hints only; all authorization is verified on the backend.
  bool sameLoginAs(AuthSession other) =>
      sessionId != null && other.sessionId != null
      ? sessionId == other.sessionId && userId == other.userId
      : accessToken == other.accessToken;
}
