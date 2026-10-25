import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';

import '../domain/operations_repository.dart';
import 'operations_view.dart';

class OperationsScreen extends StatelessWidget {
  const OperationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCoordinator>(),
        member = session.state.activeMembership,
        user = session.state.currentUser;
    if (member == null || user == null) return const SizedBox.shrink();
    return OperationsView(
      key: ValueKey((user.id, member.id, member.role)),
      repository: getIt<OperationsRepository>(),
      workspaceId: member.workspace.id,
      membershipId: member.id,
      timezone: member.workspace.timezone,
      manager: member.role == WorkspaceRole.manager,
      isCurrent: () =>
          session.state.activeMembership?.id == member.id &&
          session.state.currentUser?.id == user.id &&
          (session.state.status == SessionStatus.authenticatedManager ||
              session.state.status == SessionStatus.authenticatedEmployee),
    );
  }
}
