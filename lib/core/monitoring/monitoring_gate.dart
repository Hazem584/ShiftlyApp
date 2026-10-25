import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shiftly/core/monitoring/app_monitor.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';
import 'package:url_launcher/url_launcher.dart';

// Firebase is currently a tester-only channel. Production builds opt out.
const releaseChannel = String.fromEnvironment(
  'SHIFTLY_RELEASE_CHANNEL',
  defaultValue: 'firebase',
);

bool validReleaseUrl(String value) {
  final uri = Uri.tryParse(value);
  return uri != null &&
      uri.scheme == 'https' &&
      uri.host == 'appdistribution.firebase.google.com' &&
      !uri.hasPort &&
      !uri.hasQuery &&
      !uri.hasFragment &&
      RegExp(r'^/testerapps/[A-Za-z0-9:._-]+/releases/[A-Za-z0-9_-]+/?$')
          .hasMatch(uri.path) &&
      uri.userInfo.isEmpty;
}

class MonitoringGate extends StatefulWidget {
  const MonitoringGate({
    super.key,
    required this.apiClient,
    required this.authentication,
    required this.child,
    this.releaseClient,
    this.openRelease,
  });
  final Dio apiClient;
  final AuthenticationService authentication;
  final Widget child;
  final Dio? releaseClient;
  final Future<bool> Function(Uri)? openRelease;
  @override
  State<MonitoringGate> createState() => _MonitoringGateState();
}

class _MonitoringGateState extends State<MonitoringGate>
    with WidgetsBindingObserver {
  late final Dio _public;
  AppMonitor? _monitor;
  PackageInfo? _info;
  Map<String, dynamic>? _release;
  final Set<int> _deferred = {};
  Timer? _timer;
  bool _initial = true;
  bool _checking = false;
  bool _launching = false;
  bool _launchFailed = false;
  bool _attemptedUpdate = false;
  String get _platform => kIsWeb ? 'web' : defaultTargetPlatform.name;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _public =
        widget.releaseClient ??
        Dio(
          BaseOptions(
            baseUrl: widget.apiClient.options.baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
          ),
        );
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        unawaited(_check());
      }
    });
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      _info = await PackageInfo.fromPlatform().timeout(
        const Duration(seconds: 10),
      );
      if (!mounted) return;
      _monitor = AppMonitor(widget.apiClient, widget.authentication, _info!)
        ..start();
      await _check();
    } catch (_) {
      /* Existing app remains available if metadata is unavailable. */
    } finally {
      if (mounted) setState(() => _initial = false);
    }
  }

  Future<void> _check() async {
    if (_checking ||
        _info == null ||
        releaseChannel != 'firebase' ||
        !['android', 'ios'].contains(_platform)) {
      return;
    }
    _checking = true;
    try {
      final result = await _public.get<Object?>(
        '/platform/release',
        queryParameters: {
          'platform': _platform,
          'channel': releaseChannel,
          'build': int.tryParse(_info!.buildNumber) ?? 0,
        },
      );
      final body = result.data;
      if (!mounted || body is! Map) return;
      final release = body['release'];
      if (release == null) {
        setState(() => _release = null);
      } else if (release is Map &&
          release['build'] is int &&
          (release['build'] as int) > (int.tryParse(_info!.buildNumber) ?? 0) &&
          (release['platform'] == null || release['platform'] == _platform) &&
          (release['channel'] == null ||
              release['channel'] == releaseChannel) &&
          release['required'] is bool &&
          release['version'] is String &&
          release['message'] is String &&
          release['url'] is String &&
          validReleaseUrl(release['url'] as String)) {
        setState(() {
          if (_release?['build'] != release['build'] ||
              _release?['url'] != release['url']) {
            _attemptedUpdate = false;
            _launchFailed = false;
          }
          _release = Map<String, dynamic>.from(release);
        });
      } else {
        setState(() => _release = null);
      }
    } catch (_) {
      /* Retry on resume and periodically; keep an existing required gate. */
    } finally {
      _checking = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_check());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _monitor?.dispose();
    _public.close(force: true);
    super.dispose();
  }

  Future<void> _update() async {
    if (_launching || _release == null) return;
    setState(() {
      _launching = true;
      _attemptedUpdate = true;
      _launchFailed = false;
    });
    try {
      final uri = Uri.parse(_release!['url'] as String);
      final opened =
          await (widget.openRelease?.call(uri) ??
                  launchUrl(uri, mode: LaunchMode.externalApplication))
              .timeout(const Duration(seconds: 15));
      if (mounted) setState(() => _launchFailed = !opened);
    } catch (_) {
      if (mounted) setState(() => _launchFailed = true);
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = Localizations.localeOf(context).languageCode == 'ar';
    if (_initial) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final release = _release;
    if (release == null || _deferred.contains(release['build'])) {
      return widget.child;
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.system_update, size: 64),
                  const SizedBox(height: 24),
                  Text(
                    ar ? 'تحديث جديد للتطبيق' : 'App update available',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text('${release['version']} (${release['build']})'),
                  const SizedBox(height: 16),
                  Text(
                    release['message'] as String,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ar
                        ? 'هيفتح Firebase App Distribution لتنزيل الإصدار. التثبيت يحتاج موافقة الجهاز وحساب مختبر مصرح له.'
                        : 'Opens Firebase App Distribution to download this release. Installation requires device approval and an authorized tester account.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (_launchFailed)
                    Text(
                      ar
                          ? 'تعذر فتح رابط التحديث. حاول مرة أخرى.'
                          : 'Could not open the update link. Try again.',
                    ),
                  FilledButton(
                    onPressed: _launching ? null : _update,
                    child: Text(ar ? 'حدّث الآن' : 'Update now'),
                  ),
                  TextButton(
                    onPressed: () => unawaited(_check()),
                    child: Text(
                      ar ? 'إعادة التحقق من التحديث' : 'Check update again',
                    ),
                  ),
                  if (_attemptedUpdate)
                    Text(
                      ar
                          ? 'لو حساب المختبر أو الجهاز مش قادر يثبت الإصدار، تقدر تكمل مؤقتًا وتحاول لاحقًا.'
                          : 'If your tester account or device cannot install this release, continue temporarily and retry later.',
                    ),
                  if (release['required'] != true || _attemptedUpdate)
                    TextButton(
                      onPressed: () => setState(
                        () => _deferred.add(release['build'] as int),
                      ),
                      child: Text(
                        release['required'] == true
                            ? (ar ? 'المتابعة مؤقتًا' : 'Continue temporarily')
                            : (ar ? 'لاحقًا' : 'Later'),
                      ),
                    ),
                  if (release['required'] == true)
                    Text(
                      ar
                          ? 'التحديث مطلوب للمتابعة.'
                          : 'Update required to continue.',
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
