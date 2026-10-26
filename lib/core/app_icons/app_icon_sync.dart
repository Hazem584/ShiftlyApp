import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Downloads only a selection key. Launcher artwork is always bundled natively.
class AppIconSync with WidgetsBindingObserver {
  AppIconSync(
    this.client, {
    MethodChannel? channel,
    bool? enabled,
    DateTime Function()? now,
  }) : channel = channel ?? const MethodChannel('shiftly/app_icons'),
       enabled =
           enabled ??
           (!kIsWeb &&
               [
                 TargetPlatform.android,
                 TargetPlatform.iOS,
               ].contains(defaultTargetPlatform)),
       now = now ?? DateTime.now;
  final Dio client;
  final MethodChannel channel;
  final bool enabled;
  final DateTime Function() now;
  Timer? _timer;
  bool _busy = false, _disposed = false;
  DateTime? _lastCheck;
  void Function()? _cancelNative;

  Future<Object?> _invoke(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    final completion = Completer<Object?>();
    final timer = Timer(const Duration(seconds: 10), () {
      if (!completion.isCompleted) {
        completion.completeError(TimeoutException('Launcher API timed out'));
      }
    });
    _cancelNative = () {
      timer.cancel();
      if (!completion.isCompleted) {
        completion.completeError(StateError('Icon synchronizer disposed'));
      }
    };
    channel
        .invokeMethod<Object?>(method, arguments)
        .then(
          (value) {
            if (!completion.isCompleted) completion.complete(value);
          },
          onError: (Object error, StackTrace stack) {
            if (!completion.isCompleted) completion.completeError(error, stack);
          },
        );
    try {
      return await completion.future;
    } finally {
      timer.cancel();
      _cancelNative = null;
    }
  }

  void start() {
    if (!enabled) return;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(synchronize());
    });
    _timer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        unawaited(synchronize());
      }
    });
  }

  Future<void> synchronize() async {
    if (!enabled ||
        _busy ||
        _disposed ||
        (_lastCheck != null &&
            now().difference(_lastCheck!) < const Duration(seconds: 30))) {
      return;
    }
    _busy = true;
    _lastCheck = now();
    try {
      final capability = await _invoke('capabilities');
      if (_disposed || capability is! Map || capability['supported'] != true) {
        return;
      }
      final available = capability['icons'];
      if (available is! Map) return;
      final response = await client.get<Object?>(
        '/platform/app-icons/selection',
      );
      if (_disposed) return;
      final config = response.data;
      if (config is! Map) return;
      final key = config['key'], sha = config['sha256'];
      if (key is! String ||
          !(key == 'default' || RegExp(r'^icon_[a-f0-9]{64}$').hasMatch(key))) {
        return;
      }
      if (key == 'default') {
        if (available['default'] != 'default') return;
      } else if (sha is! String ||
          key != 'icon_$sha' ||
          available[key] != sha) {
        return;
      }
      if (capability['current'] == key) return;
      await _invoke('select', {'key': key});
    } catch (_) {
      /* Offline, unsupported build or OS failure: keep the existing icon. */
    } finally {
      _busy = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(synchronize());
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _cancelNative?.call();
    WidgetsBinding.instance.removeObserver(this);
    client.close(force: true);
  }
}
