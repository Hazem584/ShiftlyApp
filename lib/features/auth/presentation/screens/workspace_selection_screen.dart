import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/auth/data/models/current_user.dart';

class WorkspaceSelectionScreen extends StatelessWidget {
  const WorkspaceSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SessionCoordinator, SessionState>(
        builder: (context, state) {
          final memberships =
              state.currentUser?.memberships
                  .where(
                    (item) =>
                        item.status == MembershipStatus.active &&
                        item.role != WorkspaceRole.unknown,
                  )
                  .toList(growable: false) ??
              const <WorkspaceMembership>[];
          return Scaffold(
            appBar: AppBar(
              title: Text(
                memberships.isEmpty ? 'No workspace yet' : 'Choose workspace',
              ),
              actions: [
                TextButton(
                  onPressed: context.read<SessionCoordinator>().signOut,
                  child: const Text('Sign out'),
                ),
              ],
            ),
            body: memberships.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.l),
                      child: Text(
                        'You do not have an active workspace membership. Ask a manager for an invitation, then retry.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.m),
                    itemCount: memberships.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.s),
                    itemBuilder: (context, index) {
                      final membership = memberships[index];
                      return Card(
                        child: ListTile(
                          key: Key('workspace-${membership.workspace.id}'),
                          title: Text(membership.workspace.name),
                          subtitle: Text(
                            membership.role == WorkspaceRole.manager
                                ? 'Manager'
                                : 'Employee',
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => context
                              .read<SessionCoordinator>()
                              .selectWorkspace(membership.workspace.id),
                        ),
                      );
                    },
                  ),
            floatingActionButton: memberships.isEmpty
                ? FloatingActionButton.extended(
                    onPressed: context.read<SessionCoordinator>().retry,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  )
                : null,
          );
        },
      );
}
