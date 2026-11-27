import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shiftly/core/platform/platform_gate_state.dart';
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
  State<PlatformGate> createState() => PlatformGateState();
}
