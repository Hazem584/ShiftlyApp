import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shiftly/core/app_icons/app_icon_sync.dart';
import 'package:shiftly/core/monitoring/app_monitor.dart';
import 'package:shiftly/core/monitoring/release_update_controller.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';

class MonitoringRuntime with WidgetsBindingObserver {
  MonitoringRuntime({
    required Dio api,
    required this.authentication,
    Dio? releaseClient,
    Future<bool> Function(Uri)? openRelease,
  }) : _api = api,
       _icons = AppIconSync(_publicClient(api)),
       updates = ReleaseUpdateController(
         releaseClient ?? _publicClient(api),
         openRelease,
       );

  final Dio _api;
  final AuthenticationService authentication;
  final AppIconSync _icons;
  final ReleaseUpdateController updates;
  AppMonitor? _monitor;
  PackageInfo? _info;
  Timer? _timer;
  bool _disposed = false;

  static Dio _publicClient(Dio api) => Dio(
    BaseOptions(
      baseUrl: api.options.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _icons.start();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        unawaited(checkRelease());
      }
    });
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      final info = await PackageInfo.fromPlatform().timeout(
        const Duration(seconds: 10),
      );
      if (_disposed) return;
      _info = info;
      _monitor = AppMonitor(_api, authentication, info)..start();
      await checkRelease();
    } catch (_) {
      // The app stays available if package metadata cannot be loaded.
    } finally {
      if (!_disposed) updates.finishStartup();
    }
  }

  Future<void> checkRelease() async {
    final info = _info;
    if (info == null || _disposed) return;
    await updates.check(
      platform: kIsWeb ? 'web' : defaultTargetPlatform.name,
      installedBuild: int.tryParse(info.buildNumber) ?? 0,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(checkRelease());
  }

  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _monitor?.dispose();
    _icons.dispose();
    unawaited(updates.close());
  }
}
