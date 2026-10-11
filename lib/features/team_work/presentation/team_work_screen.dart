import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';

import 'widgets/team_work_body.dart';

class TeamWorkScreen extends StatelessWidget {
  const TeamWorkScreen({super.key, this.initialTab = 'announcements'});
  final String initialTab;
  @override
  Widget build(BuildContext context) {
    final membership = context
        .watch<SessionCoordinator>()
        .state
        .activeMembership;
    if (membership == null) return const SizedBox.shrink();
    return TeamWorkBody(
      key: ValueKey('${membership.id}:${membership.role}'),
      workspaceId: membership.workspace.id,
      timezone: membership.workspace.timezone,
      manager: membership.role == WorkspaceRole.manager,
      initialTab: initialTab,
      repository: getIt<TeamWorkRepository>(),
    );
  }
}
