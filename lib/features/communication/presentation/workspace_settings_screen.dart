import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/auth/presentation/widgets/workspace_switcher.dart';
import 'package:shiftly/features/workspaces/presentation/widgets/workspace_exit_tile.dart';

import 'communication_page.dart';

class WorkspaceSettingsScreen extends StatelessWidget {
  const WorkspaceSettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCoordinator?>();
    final member = session?.state.activeMembership;
    return CommunicationPage(
      title: 'Workspace',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (member != null)
            Card(
              child: ListTile(
                title: Text(member.workspace.name),
                subtitle: Text(
                  context.tr(
                    member.role.name == 'manager' ? 'Manager' : 'Employee',
                  ),
                ),
              ),
            ),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              key: const Key('switch-workspace'),
              leading: const Icon(Icons.business_outlined),
              title: Text(context.tr('Switch workspace')),
              subtitle: Text(
                context.tr('Your role may differ between workspaces.'),
              ),
              onTap: session == null
                  ? null
                  : () => showWorkspaceSwitcher(context),
            ),
          ),
          const SizedBox(height: 24),
          const WorkspaceExitTile(),
        ],
      ),
    );
  }
}
