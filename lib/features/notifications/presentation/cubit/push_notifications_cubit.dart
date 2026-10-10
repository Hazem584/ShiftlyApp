import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/notifications/domain/entities/push_notice.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_device_repository.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_messaging.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_preference_store.dart';

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

class PushNotificationsCubit extends Cubit<PushNotificationsState> {
  PushNotificationsCubit(
    this._messaging,
    this._devices,
    this._preferences, {
    required this.onOpened,
    required this.onForeground,
  }) : super(const PushNotificationsState()) {
    _initialization = _initialize();
  }

  final PushMessaging _messaging;
  final PushDeviceRepository _devices;
  final PushPreferenceStore _preferences;
  final void Function(PushNotice notice) onOpened;
  final void Function(PushNotice notice) onForeground;
  final List<StreamSubscription<Object?>> _subscriptions = [];
  late final Future<void> _initialization;
  Future<void> _jobs = Future.value();
  FeatureSessionScope? _scope;
  PushNotice? _pending;
  int _generation = 0;
  bool _revocationPending = false;

  Future<void> _initialize() async {
    try {
      final permission = await _messaging.initialize();
      if (isClosed) return;
      emit(PushNotificationsState(permission: permission));
      if (permission == PushPermission.unsupported ||
          permission == PushPermission.unavailable) {
        return;
      }
      _subscriptions.addAll([
        _messaging.opened.listen(_opened, onError: (_) {}),
        _messaging.foreground.listen((notice) {
          if (state.enabled && _matches(notice)) onForeground(notice);
        }, onError: (_) {}),
        _messaging.tokenChanges.listen((_) {
          if (state.enabled) unawaited(refresh());
        }, onError: (_) {}),
      ]);
      final notice = await _messaging.initialNotice();
      if (notice != null && !isClosed) _opened(notice);
    } catch (_) {
      if (!isClosed) {
        emit(
          const PushNotificationsState(permission: PushPermission.unavailable),
        );
      }
    }
  }

  void bindSession(FeatureSessionScope? scope) {
    if (_scope == scope) return;
    final previous = _scope;
    _scope = scope;
    final generation = ++_generation;
    emit(PushNotificationsState(permission: state.permission));
    if (previous?.userId != null && previous?.userId != scope?.userId) {
      _pending = null;
      unawaited(
        _enqueue(() async {
          await _initialization;
          // Token invalidation also protects offline logout, when API revocation
          // cannot use an expired/removed authentication session.
          await _revoke();
        }),
      );
    }
    if (scope != null) {
      unawaited(_enqueue(() => _restore(scope, generation)));
      final notice = _pending;
      _pending = null;
      if (notice != null) _opened(notice);
    }
  }

  void discardPending() => _pending = null;

  void signedOut() {
    discardPending();
    unawaited(
      _enqueue(() async {
        await _initialization;
        if (_scope == null && !isClosed) await _revoke();
      }),
    );
  }

  bool _matches(PushNotice notice) =>
      _scope != null &&
      notice.recipientProfileId == _scope!.userId &&
      notice.workspaceId == _scope!.workspaceId;

  void _opened(PushNotice notice) {
    if (_scope == null) {
      _pending = notice;
    } else if (_matches(notice)) {
      onOpened(notice);
    }
  }

  Future<void> refresh() {
    final scope = _scope;
    final generation = _generation;
    if (scope == null) {
      return _revocationPending
          ? _enqueue(() async {
              await _revoke();
            })
          : Future.value();
    }
    return _enqueue(() => _restore(scope, generation));
  }

  Future<void> setEnabled(bool enabled) {
    if (state.busy || _scope == null) return Future.value();
    final scope = _scope!;
    final generation = _generation;
    emit(
      PushNotificationsState(
        permission: state.permission,
        enabled: state.enabled,
        busy: true,
      ),
    );
    return _enqueue(() async {
      await _initialization;
      if (!_current(scope, generation)) return;
      try {
        if (!enabled) {
          await _preferences.setEnabled(scope.userId, false);
          final installation = await _preferences.installationId();
          if (!_current(scope, generation)) return;
          // Keep failed FCM invalidation pending so resume can retry offline
          // opt-out/logout. Backend revocation still uses this installation.
          await _revoke(installationId: installation);
          if (_current(scope, generation)) {
            emit(
              PushNotificationsState(
                permission: state.permission,
                message: _revocationPending
                    ? 'Could not update mobile notifications. Try again.'
                    : null,
              ),
            );
          }
          return;
        }
        final permission = await _messaging.permission(request: true);
        if (!_current(scope, generation)) return;
        if (permission != PushPermission.granted) {
          emit(PushNotificationsState(permission: permission));
          return;
        }
        await _preferences.setEnabled(scope.userId, true);
        if (_current(scope, generation)) {
          await _register(scope, generation, permission);
        }
      } catch (_) {
        if (_current(scope, generation)) {
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

  Future<void> _restore(FeatureSessionScope scope, int generation) async {
    await _initialization;
    if (!_current(scope, generation)) return;
    try {
      final permission = await _messaging.permission();
      final enabled = await _preferences.enabled(scope.userId);
      if (!_current(scope, generation)) return;
      if (!enabled || permission != PushPermission.granted) {
        // Revoke a previously registered token when OS permission is removed.
        await _revoke();
        if (_current(scope, generation)) {
          emit(PushNotificationsState(permission: permission));
        }
        return;
      }
      await _register(scope, generation, permission);
    } catch (_) {
      if (_current(scope, generation)) {
        emit(
          PushNotificationsState(
            permission: state.permission,
            message: 'Could not update mobile notifications. Try again.',
          ),
        );
      }
    }
  }

  Future<void> _register(
    FeatureSessionScope scope,
    int generation,
    PushPermission permission,
  ) async {
    final installation = await _preferences.installationId();
    final token = await _messaging.token();
    if (!_current(scope, generation)) return;
    if (token == null || token.isEmpty) {
      emit(
        PushNotificationsState(
          permission: permission,
          message: 'Mobile notifications are not ready yet. Try again.',
        ),
      );
      return;
    }
    await _devices.register(
      installationId: installation,
      token: token,
      platform: _messaging.platform,
    );
    if (_current(scope, generation)) {
      emit(PushNotificationsState(permission: permission, enabled: true));
    }
  }

  Future<void> _revoke({String? installationId}) async {
    _revocationPending = true;
    try {
      await _devices.unregister(
        installationId ?? await _preferences.installationId(),
      );
    } catch (_) {
      // API revocation is best-effort after logout; FCM invalidation follows.
    }
    try {
      await _messaging.revokeToken();
      _revocationPending = false;
    } catch (_) {}
  }

  bool _current(FeatureSessionScope scope, int generation) =>
      !isClosed && _scope == scope && _generation == generation;

  Future<void> _enqueue(Future<void> Function() operation) {
    _jobs = _jobs.then((_) => operation()).catchError((Object _) {});
    return _jobs;
  }

  @override
  Future<void> close() async {
    _generation++;
    await super.close();
    await _initialization;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _jobs;
    await _messaging.close();
  }
}
