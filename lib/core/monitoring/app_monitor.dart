import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shiftly/core/monitoring/app_diagnostic_hooks.dart';
import 'package:shiftly/core/monitoring/telemetry_client.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';

export 'package:shiftly/core/monitoring/diagnostic_redaction.dart'
    show redactDiagnostic;

class AppMonitor with WidgetsBindingObserver {
  AppMonitor(this.api, this.authentication, this.info)
    : _telemetry = TelemetryClient(api.options.baseUrl, authentication, info);
  final Dio api;
  final AuthenticationService authentication;
  final PackageInfo info;
  final TelemetryClient _telemetry;
  late final _hooks = AppDiagnosticHooks(api, report);
  Timer? _timer;
  StreamSubscription<Object?>? _auth;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _telemetry.lifecycle =
        WidgetsBinding.instance.lifecycleState?.name ?? 'resumed';
    _hooks.attach();
    _auth = authentication.authStateChanges.listen(
      (_) => unawaited(heartbeat()),
    );
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_telemetry.lifecycle == 'resumed') unawaited(heartbeat());
    });
    unawaited(heartbeat());
  }

  Future<void> heartbeat() => _telemetry.heartbeat();

  Future<void> report(
    String kind,
    String message,
    StackTrace stack, {
    String? requestId,
  }) => _telemetry.report(kind, message, stack, requestId: requestId);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _telemetry.lifecycle = state.name;
    unawaited(heartbeat());
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    unawaited(_auth?.cancel());
    _hooks.detach();
    _telemetry.dispose();
  }
}
