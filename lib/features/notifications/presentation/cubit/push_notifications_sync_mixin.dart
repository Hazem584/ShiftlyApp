import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_messaging.dart';
import 'package:shiftly/features/notifications/presentation/cubit/push_notifications_cubit_base.dart';
import 'package:shiftly/features/notifications/presentation/cubit/push_notifications_state.dart';

mixin PushNotificationsSyncMixin on PushNotificationsCubitBase {
  Future<void> refresh() {
    final scope = currentScope;
    final gen = generation;
    if (scope == null) {
      return revocationPending ? enqueue(revoke) : Future.value();
    }
    return enqueue(() => restore(scope, gen));
  }

  Future<void> restore(FeatureSessionScope scope, int gen) async {
    await initialization;
    if (!isCurrent(scope, gen)) return;
    try {
      final permission = await messaging.permission();
      final enabled = await preferences.enabled(scope.userId);
      if (!isCurrent(scope, gen)) return;
      if (!enabled || permission != PushPermission.granted) {
        await revoke();
        if (isCurrent(scope, gen)) {
          emit(PushNotificationsState(permission: permission));
        }
        return;
      }
      await registerDevice(scope, gen, permission);
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
  }

  Future<void> registerDevice(
    FeatureSessionScope scope,
    int gen,
    PushPermission permission,
  ) async {
    final installation = await preferences.installationId();
    final token = await messaging.token();
    if (!isCurrent(scope, gen)) return;
    if (token == null || token.isEmpty) {
      emit(
        PushNotificationsState(
          permission: permission,
          message: 'Mobile notifications are not ready yet. Try again.',
        ),
      );
      return;
    }
    await devices.register(
      installationId: installation,
      token: token,
      platform: messaging.platform,
    );
    if (isCurrent(scope, gen)) {
      emit(PushNotificationsState(permission: permission, enabled: true));
    }
  }
}
