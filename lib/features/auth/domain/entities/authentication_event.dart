import 'package:shiftly/features/auth/domain/entities/auth_session.dart';
import 'package:shiftly/features/auth/domain/entities/authentication_event_type.dart';

class AuthenticationEvent {
  const AuthenticationEvent(this.type);

  final AuthenticationEventType type;
}
