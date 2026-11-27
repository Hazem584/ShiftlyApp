import 'dart:async';

import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_messaging.dart';
import 'package:shiftly/features/notifications/presentation/cubit/push_notifications_cubit_base.dart';
import 'package:shiftly/features/notifications/presentation/cubit/push_notifications_state.dart';
import 'package:shiftly/features/notifications/presentation/cubit/push_notifications_sync_mixin.dart';
import 'package:shiftly/features/notifications/presentation/cubit/push_notifications_toggle_mixin.dart';

export 'package:shiftly/features/notifications/presentation/cubit/push_notifications_state.dart';

class PushNotificationsCubit extends PushNotificationsCubitBase
    with PushNotificationsSyncMixin, PushNotificationsToggleMixin {
  PushNotificationsCubit(
    super.messaging,
    super.devices,
    super.preferences, {
    required super.onOpened,
    required super.onForeground,
  }) {
    initialization = _initialize();
  }

  Future<void> _initialize() async {
    try {
      final perm = await messaging.initialize();
      if (isClosed) return;
      emit(PushNotificationsState(permission: perm));
      if (perm == PushPermission.unsupported ||
          perm == PushPermission.unavailable) {
        return;
      }
      subscriptions.addAll([
        messaging.opened.listen(handleOpened, onError: (_) {}),
        messaging.foreground.listen((n) {
          if (state.enabled && matches(n)) onForeground(n);
        }, onError: (_) {}),
        messaging.tokenChanges.listen((_) {
          if (state.enabled) unawaited(refresh());
        }, onError: (_) {}),
      ]);
      final notice = await messaging.initialNotice();
      if (notice != null && !isClosed) handleOpened(notice);
    } catch (_) {
      if (!isClosed) {
        emit(
          const PushNotificationsState(permission: PushPermission.unavailable),
        );
      }
    }
  }

  void bindSession(FeatureSessionScope? scope) {
    if (currentScope == scope) return;
    final previous = currentScope;
    currentScope = scope;
    final gen = ++generation;
    emit(PushNotificationsState(permission: state.permission));
    if (previous?.userId != null && previous?.userId != scope?.userId) {
      pendingNotice = null;
      unawaited(enqueue(() async {
        await initialization;
        await revoke();
      }));
    }
    if (scope != null) {
      unawaited(enqueue(() => restore(scope, gen)));
      final notice = pendingNotice;
      pendingNotice = null;
      if (notice != null) handleOpened(notice);
    }
  }

  void discardPending() => pendingNotice = null;

  void signedOut() {
    discardPending();
    unawaited(
      enqueue(() async {
        await initialization;
        if (currentScope == null && !isClosed) await revoke();
      }),
    );
  }
}
