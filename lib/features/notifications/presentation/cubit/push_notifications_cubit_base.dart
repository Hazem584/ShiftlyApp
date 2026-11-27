import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/notifications/domain/entities/push_notice.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_device_repository.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_messaging.dart';
import 'package:shiftly/features/notifications/domain/repositories/push_preference_store.dart';
import 'package:shiftly/features/notifications/presentation/cubit/push_notifications_state.dart';

abstract class PushNotificationsCubitBase
    extends Cubit<PushNotificationsState> {
  PushNotificationsCubitBase(
    this.messaging,
    this.devices,
    this.preferences, {
    required this.onOpened,
    required this.onForeground,
  }) : super(const PushNotificationsState());

  final PushMessaging messaging;
  final PushDeviceRepository devices;
  final PushPreferenceStore preferences;
  final void Function(PushNotice notice) onOpened, onForeground;
  final List<StreamSubscription<Object?>> subscriptions = [];
  late final Future<void> initialization;
  Future<void> jobs = Future.value();
  FeatureSessionScope? currentScope;
  PushNotice? pendingNotice;
  var generation = 0, revocationPending = false;

  bool matches(PushNotice notice) =>
      currentScope != null &&
      notice.recipientProfileId == currentScope!.userId &&
      (notice.taskId != null ||
          notice.workspaceId == currentScope!.workspaceId);

  void handleOpened(PushNotice notice) {
    if (currentScope == null) {
      pendingNotice = notice;
    } else if (matches(notice)) {
      onOpened(notice);
    }
  }

  Future<void> revoke({String? installationId}) async {
    revocationPending = true;
    try {
      final id = installationId ?? await preferences.installationId();
      await devices.unregister(id);
    } catch (_) {}
    try {
      await messaging.revokeToken();
      revocationPending = false;
    } catch (_) {}
  }

  bool isCurrent(FeatureSessionScope scope, int gen) =>
      !isClosed && currentScope == scope && generation == gen;

  Future<void> enqueue(Future<void> Function() operation) =>
      jobs = jobs.then((_) => operation()).catchError((Object _) {});

  @override
  Future<void> close() async {
    generation++;
    await super.close();
    await initialization;
    for (final s in subscriptions) {
      await s.cancel();
    }
    await jobs;
    await messaging.close();
  }
}
