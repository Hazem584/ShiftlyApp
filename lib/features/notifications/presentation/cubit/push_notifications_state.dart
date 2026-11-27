import 'package:equatable/equatable.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_messaging.dart';

class PushNotificationsState extends Equatable {
  const PushNotificationsState({
    this.permission = PushPermission.notDetermined,
    this.enabled = false,
    this.busy = false,
    this.message,
  });
  final PushPermission permission;
  final bool enabled;
  final bool busy;
  final String? message;

  @override
  List<Object?> get props => [permission, enabled, busy, message];
}
