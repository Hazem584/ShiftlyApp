import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shiftly/core/monitoring/telemetry_error_payload.dart';
import 'package:shiftly/core/monitoring/telemetry_metadata.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';
import 'package:uuid/uuid.dart';

/// Best-effort, authenticated diagnostics. No errors are saved for replay.
class TelemetryClient {
  TelemetryClient(String baseUrl, this._authentication, this._info)
    : _transport = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
        ),
      );

  final AuthenticationService _authentication;
  final PackageInfo _info;
  final Dio _transport;
  String _sessionId = const Uuid().v4();
  String? _owner;
  String lifecycle = 'resumed';
  bool _disposed = false, _sendingHeartbeat = false;
  int _sent = 0;
  DateTime _window = DateTime.now();

  Map<String, Object> get _metadata =>
      telemetryMetadata(_info, _sessionId, lifecycle);

  Options? _identify() {
    if (_disposed) return null;
    final session = _authentication.currentSession;
    final user = session?.userId;
    if (session != null && user == null) return null;
    if (_owner != user) {
      _owner = user;
      _sessionId = const Uuid().v4();
      _sent = 0;
    }
    return session == null
        ? null
        : Options(headers: {'Authorization': 'Bearer ${session.accessToken}'});
  }

  Future<void> heartbeat() async {
    final options = _identify();
    if (options == null || _sendingHeartbeat) return;
    _sendingHeartbeat = true;
    try {
      await _transport.post<Object?>(
        '/telemetry/heartbeat',
        data: _metadata,
        options: options,
      );
    } catch (_) {
      // Diagnostics must not interrupt the app.
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
    final options = _identify();
    if (options == null) return;
    final now = DateTime.now();
    if (now.difference(_window) > const Duration(minutes: 1)) {
      _window = now;
      _sent = 0;
    }
    if (_sent >= 10) return;
    _sent++;
    try {
      await _transport.post<Object?>(
        '/telemetry/errors',
        options: options,
        data: {
          ..._metadata,
          ...telemetryErrorPayload(kind, message, stack, requestId),
        },
      );
    } catch (_) {
      // Do not recursively report telemetry failures.
    }
  }

  void dispose() {
    _disposed = true;
    _transport.close(force: true);
  }
}
