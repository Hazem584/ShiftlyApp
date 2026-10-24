import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';
import 'package:shiftly/features/device_sessions/data/api_device_sessions_repository.dart';
import 'package:shiftly/features/device_sessions/domain/device_sessions_repository.dart';

class DeviceSessionsScope extends StatefulWidget {
  const DeviceSessionsScope({
    super.key,
    required this.api,
    required this.authentication,
    required this.child,
  });
  final Dio api;
  final AuthenticationService authentication;
  final Widget child;
  @override
  State<DeviceSessionsScope> createState() => _DeviceSessionsScopeState();
}

class _DeviceSessionsScopeState extends State<DeviceSessionsScope>
    with WidgetsBindingObserver {
  late final DeviceSessionsRepository _repository;
  StreamSubscription<Object?>? _subscription;
  Timer? _timer;
  bool _syncing = false;
  String? _registered;
  @override
  void initState() {
    super.initState();
    _repository = ApiDeviceSessionsRepository(widget.api);
    WidgetsBinding.instance.addObserver(this);
    _subscription = widget.authentication.authStateChanges.listen(
      (_) => unawaited(_sync()),
    );
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        unawaited(_sync());
      }
    });
    unawaited(_sync());
  }

  Future<void> _sync() async {
    if (_syncing || !mounted) return;
    final session = widget.authentication.currentSession;
    if (session == null) {
      _registered = null;
      return;
    }
    _syncing = true;
    final identity = session.sessionId ?? session.accessToken;
    try {
      await _repository.registerCurrent();
      _registered = identity;
    } catch (_) {
      /* Authentication/interceptor handles revocation; metadata can retry. */
    } finally {
      _syncing = false;
      final current = widget.authentication.currentSession;
      final next = current?.sessionId ?? current?.accessToken;
      if (mounted && next != null && next != identity && next != _registered) {
        unawaited(_sync());
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_sync());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      RepositoryProvider<DeviceSessionsRepository>.value(
        value: _repository,
        child: widget.child,
      );
}
