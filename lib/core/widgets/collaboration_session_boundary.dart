import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/session_coordinator.dart';

class CollaborationSessionBoundary extends StatefulWidget {
  const CollaborationSessionBoundary({required this.child, super.key});
  final Widget child;
  @override
  State<CollaborationSessionBoundary> createState() =>
      _CollaborationSessionBoundaryState();
}

class _CollaborationSessionBoundaryState
    extends State<CollaborationSessionBoundary> {
  String? _identity;
  bool _bound = false, _closing = false;
  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCoordinator?>();
    if (session == null) return widget.child;
    final state = session.state;
    final identity =
        '${state.currentUser?.id}:${state.activeMembership?.id}:${state.status.name}';
    if (!_bound) {
      _identity = identity;
      _bound = true;
    }
    if (!state.isAuthenticated || identity != _identity) {
      if (!_closing) {
        _closing = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final route = ModalRoute.of(context);
          if (route != null) Navigator.of(context).removeRoute(route);
        });
      }
      return const SizedBox.shrink();
    }
    return widget.child;
  }
}
