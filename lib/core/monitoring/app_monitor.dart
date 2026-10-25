import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shiftly/core/monitoring/diagnostic_redaction.dart';
import 'package:shiftly/core/monitoring/safe_exception_summary.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';
import 'package:uuid/uuid.dart';

export 'package:shiftly/core/monitoring/diagnostic_redaction.dart'
    show redactDiagnostic;

/// Best-effort authenticated diagnostics. Never retain or replay another user's errors.
class AppMonitor with WidgetsBindingObserver {
  AppMonitor(this.api, this.authentication, this.info)
    : _transport = Dio(
        BaseOptions(
          baseUrl: api.options.baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );
  final Dio api;
  final AuthenticationService authentication;
  final PackageInfo info;
  final Dio _transport;
  Options get _options => Options(
    headers: {
      'Authorization': 'Bearer ${authentication.currentSession!.accessToken}',
    },
  );
  String sessionId = const Uuid().v4();
  String? _owner;
  String _state = 'resumed';
  Timer? _timer;
  StreamSubscription<Object?>? _auth;
  late Interceptor _interceptor;
  FlutterExceptionHandler? _previousFlutter;
  bool Function(Object, StackTrace)? _previousUnhandled;
  late FlutterExceptionHandler _flutterHandler;
  late bool Function(Object, StackTrace) _unhandledHandler;
  bool _disposed = false;
  bool _sendingHeartbeat = false;
  int _sent = 0;
  DateTime _window = DateTime.now();
  String get platform => kIsWeb ? 'web' : defaultTargetPlatform.name;
  Map<String, Object> get metadata => {
    'sessionId': sessionId,
    'platform': platform,
    'version': info.version,
    'build': int.tryParse(info.buildNumber) ?? 0,
    'state': _state,
  };
  void start() {
    WidgetsBinding.instance.addObserver(this);
    _state = WidgetsBinding.instance.lifecycleState?.name ?? 'resumed';
    _previousFlutter = FlutterError.onError;
    _flutterHandler = (details) {
      unawaited(
        report(
          'flutter',
          diagnosticExceptionSummary(details.exception),
          details.stack ?? StackTrace.current,
        ),
      );
      _previousFlutter?.call(details);
    };
    FlutterError.onError = _flutterHandler;
    _previousUnhandled = PlatformDispatcher.instance.onError;
    _unhandledHandler = (error, stack) {
      unawaited(report('unhandled', diagnosticExceptionSummary(error), stack));
      return _previousUnhandled?.call(error, stack) ?? false;
    };
    PlatformDispatcher.instance.onError = _unhandledHandler;
    _interceptor = InterceptorsWrapper(
      onError: (error, handler) {
        if (!error.requestOptions.path.startsWith('/telemetry/')) {
          final body = error.response?.data;
          final rawCode = body is Map ? body['code']?.toString() : null;
          final code =
              rawCode != null && RegExp(r'^[A-Z0-9_]{1,80}$').hasMatch(rawCode)
              ? rawCode
              : error.type.name;
          unawaited(
            report(
              'api',
              '${error.requestOptions.method} ${error.response?.statusCode ?? 0} $code',
              StackTrace.empty,
              requestId: error.response?.headers.value('x-request-id'),
            ),
          );
        }
        handler.next(error);
      },
    );
    api.interceptors.insert(0, _interceptor);
    _auth = authentication.authStateChanges.listen(
      (_) => unawaited(heartbeat()),
    );
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_state == 'resumed') unawaited(heartbeat());
    });
    unawaited(heartbeat());
  }

  bool _identify() {
    if (_disposed) return false;
    String? user;
    final token = authentication.currentSession?.accessToken;
    if (token != null) {
      try {
        final payload = jsonDecode(
          utf8.decode(
            base64Url.decode(base64Url.normalize(token.split('.')[1])),
          ),
        );
        if (payload is Map && payload['sub'] is String) {
          user = payload['sub'] as String;
        }
      } catch (_) {
        return false;
      }
    }
    if (_owner != user) {
      _owner = user;
      sessionId = const Uuid().v4();
      _sent = 0;
    }
    return user != null;
  }

  Future<void> heartbeat() async {
    if (!_identify() || _sendingHeartbeat) return;
    _sendingHeartbeat = true;
    try {
      await _transport.post<Object?>(
        '/telemetry/heartbeat',
        data: metadata,
        options: _options,
      );
    } catch (_) {
      /* Diagnostics must not interrupt the app. */
    } finally {
      _sendingHeartbeat = false;
    }
  }

  Future<void> report(
    String kind,
    String message,
    StackTrace stack, {
    String? requestId,
  }) async {
    if (!_identify()) return;
    if (DateTime.now().difference(_window) > const Duration(minutes: 1)) {
      _window = DateTime.now();
      _sent = 0;
    }
    if (_sent >= 10) return;
    _sent++;
    try {
      await _transport.post<Object?>(
        '/telemetry/errors',
        options: _options,
        data: {
          ...metadata,
          'kind': kind,
          'message': redactDiagnostic(message, 2000),
          'stack': redactDiagnostic(stack.toString(), 8000),
          if (requestId != null &&
              RegExp(r'^[A-Za-z0-9][A-Za-z0-9._:-]{0,127}$')
                  .hasMatch(requestId))
            'requestId': requestId,
        },
      );
    } catch (_) {
      /* Do not recursively report telemetry failures. */
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _state = state.name;
    unawaited(heartbeat());
  }

  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    unawaited(_auth?.cancel());
    api.interceptors.remove(_interceptor);
    _transport.close(force: true);
    if (identical(FlutterError.onError, _flutterHandler)) {
      FlutterError.onError = _previousFlutter;
    }
    if (identical(PlatformDispatcher.instance.onError, _unhandledHandler)) {
      PlatformDispatcher.instance.onError = _previousUnhandled;
    }
  }
}
