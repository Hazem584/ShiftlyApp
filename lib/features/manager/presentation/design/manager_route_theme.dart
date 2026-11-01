import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';

import 'manager_theme.dart';

/// Standalone notification/deep-link routes use the active role's presentation.
class ManagerRouteTheme extends StatelessWidget {
  const ManagerRouteTheme({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final member = context.watch<SessionCoordinator?>()?.state.activeMembership;
    return member?.role == WorkspaceRole.manager
        ? ManagerTheme(child: child)
        : child;
  }
}
