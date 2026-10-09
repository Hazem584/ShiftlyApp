export 'package:shiftly/features/auth/domain/entities/authentication_event.dart';
export 'package:shiftly/features/auth/domain/entities/authentication_event_type.dart';
export 'package:shiftly/features/auth/domain/entities/authentication_result.dart';

class AuthSession {
  const AuthSession({required this.accessToken});

  final String accessToken;
}
