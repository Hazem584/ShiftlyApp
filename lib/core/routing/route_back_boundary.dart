import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RouteBackBoundary extends StatelessWidget {
  const RouteBackBoundary({
    required this.fallback,
    required this.child,
    super.key,
  });
  final String? fallback;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    return PopScope<Object?>(
      canPop: router.canPop() || fallback == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && fallback != null) router.go(fallback!);
      },
      child: child,
    );
  }
}
