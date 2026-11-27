import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';
import 'package:shiftly/features/communication/presentation/workspace_switcher_list.dart';

import 'communication_page.dart';

class WorkspaceSwitcherScreen extends StatefulWidget {
  const WorkspaceSwitcherScreen({
    required this.coordinator,
    this.onSwitchingChanged,
    super.key,
  });
  final SessionCoordinator coordinator;
  final ValueChanged<bool>? onSwitchingChanged;
  @override
  State<WorkspaceSwitcherScreen> createState() =>
      _WorkspaceSwitcherScreenState();
}

class _WorkspaceSwitcherScreenState extends State<WorkspaceSwitcherScreen> {
  String? _selected;
  bool _busy = false;
  String? _error;

  Future<void> _switch() async {
    final id = _selected;
    if (_busy ||
        id == null ||
        id == widget.coordinator.state.activeMembership?.workspace.id) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    widget.onSwitchingChanged?.call(true);
    final result = await widget.coordinator.switchWorkspace(id);
    widget.onSwitchingChanged?.call(false);
    if (!mounted) return;
    if (result == WorkspaceSwitchResult.failure) {
      setState(() {
        _busy = false;
        _error = 'Unable to switch workspace. Please retry.';
      });
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SessionCoordinator, SessionState>(
        bloc: widget.coordinator,
        builder: (context, _) {
          final current =
              widget.coordinator.state.activeMembership?.workspace.id;
          return PopScope(
            canPop: !_busy,
            child: CommunicationPage(
              title: 'Switch workspace',
              guardSession: false,
              subtitle: 'Your role may differ between workspaces.',
              footer: buildWorkspaceSwitcherFooter(
                context,
                busy: _busy,
                canApply: _selected != null && _selected != current,
                onApply: _switch,
              ),
              child: buildWorkspaceMembershipList(
                context,
                memberships: widget.coordinator.selectableMemberships,
                selected: _selected,
                current: current,
                busy: _busy,
                error: _error,
                onSelect: (id) => setState(() => _selected = id),
              ),
            ),
          );
        },
      );
}
