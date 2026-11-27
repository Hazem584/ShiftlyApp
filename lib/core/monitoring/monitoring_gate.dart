import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/monitoring/monitoring_runtime.dart';
import 'package:shiftly/core/monitoring/release_update_controller.dart';
import 'package:shiftly/core/monitoring/release_update_screen.dart';
import 'package:shiftly/core/monitoring/release_update_state.dart';
import 'package:shiftly/core/widgets/brand_session_loading.dart';
import 'package:shiftly/features/auth/domain/repositories/authentication_service.dart';

export 'package:shiftly/core/monitoring/release_policy.dart'
    show releaseChannel, validReleaseUrl;

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

class _MonitoringGateState extends State<MonitoringGate> {
  late final MonitoringRuntime _runtime;

  @override
  void initState() {
    super.initState();
    _runtime = MonitoringRuntime(
      api: widget.apiClient,
      authentication: widget.authentication,
      releaseClient: widget.releaseClient,
      openRelease: widget.openRelease,
    )..start();
  }

  @override
  void dispose() {
    _runtime.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ReleaseUpdateController, ReleaseUpdateState>(
        bloc: _runtime.updates,
        builder: (context, state) {
          if (state.initial) return const BrandSessionLoading();
          final release = state.visibleRelease;
          if (release == null) return widget.child;
          return ReleaseUpdateScreen(
            release: release,
            launching: state.launching,
            launchFailed: state.launchFailed,
            attemptedUpdate: state.attemptedUpdate,
            onUpdate: _runtime.updates.launch,
            onCheck: () => unawaited(_runtime.checkRelease()),
            onDefer: () => _runtime.updates.defer(release['build'] as int),
          );
        },
      );
}
