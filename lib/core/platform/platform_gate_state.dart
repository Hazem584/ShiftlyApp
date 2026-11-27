import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shiftly/core/platform/platform_blocked_screen.dart';
import 'package:shiftly/core/platform/platform_gate.dart';
import 'package:shiftly/core/platform/platform_gate_content.dart';
import 'package:shiftly/core/widgets/brand_session_loading.dart';

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
    _interceptor = InterceptorsWrapper(
      onError: (error, handler) {
        _inspectError(error);
        handler.next(error);
      },
    );
    widget.apiClient.interceptors.insert(0, _interceptor);
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
    final body = error.response?.data;
    if (!mounted || body is! Map) return;
    if (body['code'] == 'ACCOUNT_DELETED') {
      unawaited(widget.authentication.signOut());
    } else if (body['code'] == 'ACCOUNT_SUSPENDED') {
      setState(
        () => _suspension = body['message']?.toString() ?? 'Account suspended',
      );
    } else if (body['code'] == 'PLATFORM_UNAVAILABLE' &&
        body['platform'] is Map) {
      setState(
        () => _status = Map<String, dynamic>.from(body['platform'] as Map),
      );
    }
  }

  Future<void> _refresh() async {
    if (_checking || !mounted) return;
    setState(() => _checking = true);
    try {
      final response = await widget.statusClient.get<Object?>(
        '/platform/status',
      );
      if (!mounted) return;
      final data = response.data;
      if (data is! Map ||
          !const [
            'OPERATIONAL',
            'MAINTENANCE',
            'UPDATING',
            'DISABLED',
          ].contains(data['mode'])) {
        throw const FormatException('Invalid platform status');
      }
      setState(() {
        _status = Map<String, dynamic>.from(data);
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
  Widget build(BuildContext context) {
    if (_status == null && !_failed && _suspension == null) {
      return const BrandSessionLoading();
    }
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final blocked =
        _status == null ||
        _status?['mode'] != 'OPERATIONAL' ||
        _suspension != null;
    final announcement = _status?['announcement']?.toString().trim() ?? '';
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(
          offstage: blocked,
          child: TickerMode(
            enabled: !blocked,
            child: ExcludeFocus(
              excluding: blocked,
              child: Column(
                children: [
                  if (announcement.isNotEmpty)
                    buildPlatformAnnouncementBanner(context, announcement),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ),
        ),
        if (blocked)
          PlatformBlockedScreen(
            arabic: arabic,
            status: _status,
            suspension: _suspension,
            failed: _failed,
            checking: _checking,
            onRefresh: _refresh,
            onSignOut: () => widget.authentication.signOut(),
          ),
      ],
    );
  }
}
