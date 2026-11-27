import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/core/widgets/access_screen.dart';
import 'package:shiftly/features/auth/domain/entities/current_user.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_cubit.dart';

void openActiveWorkspaceRoute(BuildContext context) {
  final session = context.read<SessionCoordinator>().state;
  if (session.isAuthenticated) {
    context.go(
      session.status == SessionStatus.authenticatedManager
          ? '/dashboard'
          : '/employee',
    );
  }
}

Future<void> respondToWorkspaceInvitation(
  BuildContext context,
  String invitationId, {
  required bool accept,
}) async {
  final cubit = context.read<WorkspacesCubit>();
  final success = accept
      ? await cubit.acceptById(invitationId)
      : await cubit.decline(invitationId);
  if (!context.mounted) return;
  if (success) {
    if (accept) {
      openActiveWorkspaceRoute(context);
    } else {
      ToastService.success(context, message: 'Invitation declined.');
    }
  } else {
    ToastService.error(
      context,
      message:
          cubit.state.failure?.message ??
          'Could not update invitation. Please try again.',
    );
  }
}

Future<void> selectWorkspaceMembership(
  BuildContext context,
  WorkspaceMembership membership,
) async {
  final result = await context.read<SessionCoordinator>().selectWorkspace(
    membership.workspace.id,
  );
  if (!context.mounted) return;
  if (result == WorkspaceSwitchResult.success) {
    openActiveWorkspaceRoute(context);
  } else if (result == WorkspaceSwitchResult.failure ||
      result == WorkspaceSwitchResult.invalid ||
      result == WorkspaceSwitchResult.noAlternative) {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (pageContext) => AccessScreen(
          title: 'Workspace unavailable',
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(pageContext).pop(),
              child: Text(context.tr('Choose another workspace')),
            ),
          ],
          children: [
            Text(
              context.tr('This workspace is unavailable.'),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('Choose another workspace or contact your manager.'),
            ),
          ],
        ),
      ),
    );
  }
}
