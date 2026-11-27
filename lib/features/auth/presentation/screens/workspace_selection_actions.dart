import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/features/auth/presentation/screens/workspace_entry_screen.dart';
import 'package:shiftly/features/auth/presentation/screens/workspace_selection_navigation.dart';
import 'package:shiftly/features/workspaces/presentation/cubit/workspaces_cubit.dart';

export 'package:shiftly/features/auth/presentation/screens/workspace_selection_navigation.dart';

Future<void> promptCreateWorkspace(BuildContext context) async {
  final result = await Navigator.of(context).push(
    MaterialPageRoute<({String value, String timezone})>(
      builder: (_) => const WorkspaceEntryScreen(),
    ),
  );
  if (!context.mounted || result == null) return;
  final success = await context.read<WorkspacesCubit>().create(
    name: result.value,
    timezone: result.timezone,
  );
  if (!context.mounted) return;
  if (success) {
    openActiveWorkspaceRoute(context);
  } else {
    ToastService.error(context, message: 'Could not create workspace.');
  }
}

Future<void> promptAcceptInvitationToken(BuildContext context) async {
  final result = await Navigator.of(context).push(
    MaterialPageRoute<({String value, String timezone})>(
      builder: (_) => const WorkspaceEntryScreen(join: true),
    ),
  );
  if (!context.mounted || result == null) return;
  final success = await context.read<WorkspacesCubit>().accept(result.value);
  if (!context.mounted) return;
  if (success) {
    openActiveWorkspaceRoute(context);
  } else {
    ToastService.error(
      context,
      message:
          context.read<WorkspacesCubit>().state.failure?.message ??
          'Could not accept invitation.',
    );
  }
}
