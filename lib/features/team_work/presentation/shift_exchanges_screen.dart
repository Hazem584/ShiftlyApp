import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/team_work/domain/shift_exchange_repository.dart';
import 'package:shiftly/features/team_work/presentation/widgets/shift_exchanges_view.dart';

class ShiftExchangesScreen extends StatelessWidget {
  const ShiftExchangesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCoordinator>(),
        member = session.state.activeMembership,
        user = session.state.currentUser;
    if (member == null || user == null) return const SizedBox.shrink();
    return ShiftExchangesView(
      key: ValueKey((user.id, member.id, member.role)),
      workspaceId: member.workspace.id,
      membershipId: member.id,
      timezone: member.workspace.timezone,
      manager: member.role == WorkspaceRole.manager,
      repository: getIt<ShiftExchangeRepository>(),
      isCurrent: () =>
          (session.state.status == SessionStatus.authenticatedEmployee ||
              session.state.status == SessionStatus.authenticatedManager) &&
          session.state.activeMembership?.id == member.id &&
          session.state.currentUser?.id == user.id,
    );
  }
}
