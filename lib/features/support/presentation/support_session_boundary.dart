import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/session_coordinator.dart';

class SupportSessionBoundary extends StatelessWidget {
  const SupportSessionBoundary({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCoordinator?>();
    if (session != null && !session.state.isAuthenticated) {
      return const SizedBox.shrink();
    }
    return KeyedSubtree(
      key: ValueKey(session?.state.currentUser?.id),
      child: child,
    );
  }
}
