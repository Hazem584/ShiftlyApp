import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/app/app_composition.dart';
import 'package:shiftly/app/app_lifecycle_listener.dart';
import 'package:shiftly/app/app_material_router.dart';
import 'package:shiftly/app/app_providers.dart';
import 'package:shiftly/app/app_push_notice_handler.dart';
import 'package:shiftly/app/app_scope_providers.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/workspace_access_monitor.dart';

class AppProvidersState extends State<AppProviders> {
  Dio? _platformStatusClient;
  WorkspaceAccessMonitor? _workspaceAccess;
  late final AppComposition _composition;
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    final push = AppPushNoticeHandler(
      composition: () => _composition,
      messengerKey: _messengerKey,
      isMounted: () => mounted,
    );
    _composition = AppComposition(
      widget.dependencies,
      isMounted: () => mounted,
      onOpened: push.openPushNotice,
      onForeground: push.showPushNotice,
    );
    final locator = widget.locator;
    final session = _composition.sessionCoordinator;
    if (locator != null && locator.isRegistered<Dio>() && session != null) {
      _workspaceAccess = WorkspaceAccessMonitor(
        locator<Dio>(),
        session,
        _composition.readSyncCubit.store,
        onRemoval: _composition.workspaceRemoval.remove,
      );
    }
  }

  @override
  void dispose() {
    _workspaceAccess?.dispose();
    _composition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = buildAppScopeProviders(
      composition: _composition,
      child: buildShiftlyMaterialApp(
        composition: _composition,
        messengerKey: _messengerKey,
        locator: widget.locator,
        platformStatusClient: (config) => _platformStatusClient ??= Dio(
          BaseOptions(
            baseUrl: config.apiBaseUrl.toString(),
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        ),
      ),
    );
    final coordinator = _composition.sessionCoordinator;
    return ShiftlyAppLifecycleListener(
      onResumed: _onResumed,
      child: coordinator == null
          ? app
          : BlocProvider<SessionCoordinator>.value(
              value: coordinator,
              child: app,
            ),
    );
  }

  void _onResumed() {
    unawaited(_workspaceAccess?.check());
    unawaited(
      _composition.tasksCubit.refresh().then((_) => _composition.openTaskTap()),
    );
    unawaited(_composition.pushNotifications?.refresh());
    unawaited(_composition.flexibleAttendanceCubit.load(refresh: true));
    unawaited(_composition.notificationsCubit.refreshUnreadCount());
    unawaited(_composition.chatGroupsCubit.refreshUnread());
    _composition.invalidateDashboardAndCalendar();
  }
}
