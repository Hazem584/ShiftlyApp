import 'package:shiftly/features/notifications/domain/repositories/push_messaging.dart';
import 'package:shiftly/features/notifications/presentation/cubit/push_notifications_cubit_base.dart';
import 'package:shiftly/features/notifications/presentation/cubit/push_notifications_state.dart';
import 'package:shiftly/features/notifications/presentation/cubit/push_notifications_sync_mixin.dart';

mixin PushNotificationsToggleMixin
    on PushNotificationsCubitBase, PushNotificationsSyncMixin {
  Future<void> setEnabled(bool enabled) {
    if (state.busy || currentScope == null) return Future.value();
    final scope = currentScope!;
    final gen = generation;
    emit(
      PushNotificationsState(
        permission: state.permission,
        enabled: state.enabled,
        busy: true,
      ),
    );
    return enqueue(() async {
      await initialization;
      if (!isCurrent(scope, gen)) return;
      try {
        if (!enabled) {
          await preferences.setEnabled(scope.userId, false);
          final installation = await preferences.installationId();
          if (!isCurrent(scope, gen)) return;
          await revoke(installationId: installation);
          if (isCurrent(scope, gen)) {
            emit(
              PushNotificationsState(
                permission: state.permission,
                message: revocationPending
                    ? 'Could not update mobile notifications. Try again.'
                    : null,
              ),
            );
          }
          return;
        }
        final permission = await messaging.permission(request: true);
        if (!isCurrent(scope, gen)) return;
        if (permission != PushPermission.granted) {
          emit(PushNotificationsState(permission: permission));
          return;
        }
        await preferences.setEnabled(scope.userId, true);
        if (isCurrent(scope, gen)) {
          await registerDevice(scope, gen, permission);
        }
      } catch (_) {
        if (isCurrent(scope, gen)) {
          emit(
            PushNotificationsState(
              permission: state.permission,
              message: 'Could not update mobile notifications. Try again.',
            ),
          );
        }
      }
    });
  }
}
