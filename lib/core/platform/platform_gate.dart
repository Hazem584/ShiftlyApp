import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';

/// Public service status remains available while authenticated APIs are stopped.
class PlatformGate extends StatefulWidget {
  const PlatformGate({
    super.key,
    required this.statusClient,
    required this.apiClient,
    required this.authentication,
    required this.child,
  });

  final Dio statusClient;
  final Dio apiClient;
  final AuthenticationService authentication;
  final Widget child;

  @override
  State<PlatformGate> createState() => _PlatformGateState();
}

class _PlatformGateState extends State<PlatformGate>
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
      return;
    }
    if (body['code'] == 'ACCOUNT_SUSPENDED') {
      setState(
        () => _suspension = body['message']?.toString() ?? 'Account suspended',
      );
    }
    if (body['code'] == 'PLATFORM_UNAVAILABLE' && body['platform'] is Map) {
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
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final mode = _status?['mode'];
    final blocked =
        _status == null || mode != 'OPERATIONAL' || _suspension != null;
    final announcement = _status?['announcement']?.toString().trim() ?? '';
    final title = _suspension != null
        ? (arabic ? 'الحساب معلّق' : 'Account suspended')
        : (_status?['title']?.toString().trim().isNotEmpty ?? false)
        ? _status!['title'].toString()
        : switch (mode) {
            'MAINTENANCE' =>
              arabic ? 'التطبيق تحت الصيانة' : 'Under maintenance',
            'UPDATING' =>
              arabic ? 'جارٍ تحديث التطبيق' : 'An update is in progress',
            'DISABLED' =>
              arabic ? 'الخدمة متوقفة حاليًا' : 'Service unavailable',
            _ => arabic ? 'جارٍ التحقق من الخدمة' : 'Checking service status',
          };
    final message =
        _suspension ??
        (_status?['message']?.toString().trim().isNotEmpty ?? false
            ? _status!['message'].toString()
            : arabic
            ? 'حاول مجددًا بعد قليل.'
            : 'Please try again shortly.');
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
                    Material(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.campaign_outlined, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  announcement,
                                  maxLines: 5,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ),
        ),
        if (blocked)
          Scaffold(
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _suspension != null
                              ? Icons.person_off_outlined
                              : Icons.construction_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 16),
                        if (_status != null || _suspension != null)
                          Text(message, textAlign: TextAlign.center),
                        if (_failed)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text(
                              arabic
                                  ? 'تعذّر الاتصال بالخدمة. تحقّق من الإنترنت وأعد المحاولة.'
                                  : 'Could not reach the service. Check your connection and retry.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        if ((_status?['supportEmail']?.toString() ?? '')
                            .isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: SelectableText(
                              _status!['supportEmail'].toString(),
                            ),
                          ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _checking ? null : _refresh,
                          icon: _checking
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh),
                          label: Text(arabic ? 'إعادة المحاولة' : 'Try again'),
                        ),
                        if (_suspension != null)
                          TextButton(
                            onPressed: () => widget.authentication.signOut(),
                            child: Text(arabic ? 'تسجيل الخروج' : 'Sign out'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
