import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/features/communication/presentation/communication_appearance.dart';
import 'package:shiftly/features/communication/presentation/workspace_switcher_screen.dart';

Future<void> showWorkspaceSwitcher(
  BuildContext context, {
  ValueChanged<bool>? onSwitchingChanged,
}) async {
  final coordinator = context.read<SessionCoordinator>();
  await Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute(
      builder: (_) => CommunicationAppearance(
        child: WorkspaceSwitcherScreen(
          coordinator: coordinator,
          onSwitchingChanged: onSwitchingChanged,
        ),
      ),
    ),
  );
  if (context.mounted) onSwitchingChanged?.call(false);
}
