import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shiftly/core/platform/platform_gate.dart';

import 'platform_access_interceptor.dart';
import 'platform_gate_view.dart';
import 'platform_status_parser.dart';

class PlatformGateState extends State<PlatformGate>
    with WidgetsBindingObserver {
  Map<String, dynamic>? _status;
  String? _suspension;
  bool _checking = false;
  bool _failed = false;
  Timer? _timer;
  StreamSubscription<Object?>? _authSubscription;
  late final Interceptor _interceptor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _interceptor = installPlatformAccessInterceptor(
      widget.apiClient,
      _inspectError,
    );
    _authSubscription = widget.authentication.authStateChanges.listen((_) {
      if (!mounted) return;
      if (widget.authentication.currentSession == null) {
        setState(() => _suspension = null);
      }
      unawaited(_refresh());
    });
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
    unawaited(_refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refresh());
  }

  void _inspectError(DioException error) {
    if (!mounted) return;
    final update = parsePlatformAccessError(error.response?.data);
    if (update.deleted) unawaited(widget.authentication.signOut());
    if (update.suspension case final message?) {
      setState(() => _suspension = message);
    }
    if (update.status case final status?) setState(() => _status = status);
  }

  Future<void> _refresh() async {
    if (_checking || !mounted) return;
    setState(() => _checking = true);
    try {
      final status = await fetchPlatformStatus(widget.statusClient);
      if (!mounted) return;
      setState(() {
        _status = status;
        _failed = false;
      });
      if (widget.authentication.currentSession != null) {
        try {
          await widget.apiClient.get<Object?>('/platform/access');
          if (mounted) setState(() => _suspension = null);
        } on DioException catch (error) {
          _inspectError(error);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    unawaited(_authSubscription?.cancel());
    widget.apiClient.interceptors.remove(_interceptor);
    widget.statusClient.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PlatformGateView(
    status: _status,
    suspension: _suspension,
    failed: _failed,
    checking: _checking,
    onRefresh: _refresh,
    onSignOut: widget.authentication.signOut,
    child: widget.child,
  );
}
