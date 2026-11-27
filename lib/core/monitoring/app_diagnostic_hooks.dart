import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shiftly/core/monitoring/safe_exception_summary.dart';

typedef DiagnosticReporter = Future<void> Function(
  String kind,
  String message,
  StackTrace stack, {
  String? requestId,
});

class AppDiagnosticHooks {
  AppDiagnosticHooks(this._api, this._report);
  final Dio _api;
  final DiagnosticReporter _report;
  FlutterExceptionHandler? _previousFlutter;
  bool Function(Object, StackTrace)? _previousUnhandled;
  late final FlutterExceptionHandler _flutterHandler;
  late final bool Function(Object, StackTrace) _unhandledHandler;
  late final Interceptor _interceptor;

  void attach() {
    _previousFlutter = FlutterError.onError;
    _flutterHandler = (details) {
      unawaited(
        _report(
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
      unawaited(_report('unhandled', diagnosticExceptionSummary(error), stack));
      return _previousUnhandled?.call(error, stack) ?? false;
    };
    PlatformDispatcher.instance.onError = _unhandledHandler;
    _interceptor = InterceptorsWrapper(onError: _onError);
    _api.interceptors.insert(0, _interceptor);
  }

  void _onError(DioException error, ErrorInterceptorHandler handler) {
    if (!error.requestOptions.path.startsWith('/telemetry/')) {
      final body = error.response?.data;
      final rawCode = body is Map ? body['code']?.toString() : null;
      final code =
          rawCode != null && RegExp(r'^[A-Z0-9_]{1,80}$').hasMatch(rawCode)
          ? rawCode
          : error.type.name;
      unawaited(
        _report(
          'api',
          '${error.requestOptions.method} ${error.response?.statusCode ?? 0} $code',
          StackTrace.empty,
          requestId: error.response?.headers.value('x-request-id'),
        ),
      );
    }
    handler.next(error);
  }

  void detach() {
    _api.interceptors.remove(_interceptor);
    if (identical(FlutterError.onError, _flutterHandler)) {
      FlutterError.onError = _previousFlutter;
    }
    if (identical(PlatformDispatcher.instance.onError, _unhandledHandler)) {
      PlatformDispatcher.instance.onError = _previousUnhandled;
    }
  }
}
