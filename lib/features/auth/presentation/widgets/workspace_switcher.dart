import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/session_coordinator.dart';

import '../design/access_theme.dart';
import 'workspace_switcher_sheet.dart';

Future<void> showWorkspaceSwitcher(
  BuildContext context, {
  ValueChanged<bool>? onSwitchingChanged,
}) async {
  final coordinator = context.read<SessionCoordinator>();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => AccessTheme(
      child: WorkspaceSwitcherSheet(
        coordinator: coordinator,
        onSwitchingChanged: onSwitchingChanged,
      ),
    ),
  );
  if (context.mounted) onSwitchingChanged?.call(false);
}
