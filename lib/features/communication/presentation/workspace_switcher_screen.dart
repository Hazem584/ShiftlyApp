import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/session/session_state.dart';

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
        builder: (context, _) => _page(context),
      );
  Widget _page(BuildContext context) {
    final memberships = widget.coordinator.selectableMemberships;
    final current = widget.coordinator.state.activeMembership?.workspace.id;
    return PopScope(
      canPop: !_busy,
      child: CommunicationPage(
        title: 'Switch workspace',
        guardSession: false,
        subtitle: 'Your role may differ between workspaces.',
        footer: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              key: const Key('apply-workspace-switch'),
              onPressed: _busy || _selected == null || _selected == current
                  ? null
                  : _switch,
              child: Text(
                context.tr(_busy ? 'Switching workspace…' : 'Switch workspace'),
              ),
            ),
            TextButton(
              key: const Key('manage-workspace-invitations'),
              onPressed: _busy
                  ? null
                  : () {
                      Navigator.pop(context);
                      context.push('/workspaces');
                    },
              child: Text(context.tr('Workspaces and invitations')),
            ),
          ],
        ),
        child: ListView(
          key: const Key('workspace-membership-chooser'),
          padding: const EdgeInsets.all(24),
          children: [
            for (final member in memberships) ...[
              Card(
                child: ListTile(
                  key: ValueKey('workspace-${member.workspace.id}'),
                  leading: Icon(
                    (_selected ?? current) == member.workspace.id
                        ? Icons.check_circle_outline
                        : Icons.business_outlined,
                  ),
                  title: Text(member.workspace.name),
                  subtitle: Text(
                    '${context.tr(member.role.name == 'manager' ? 'Manager' : 'Employee')}${member.workspace.id == current ? ' · ${context.tr('Currently active')}' : ''}',
                  ),
                  selected: (_selected ?? current) == member.workspace.id,
                  onTap: _busy
                      ? null
                      : () => setState(() => _selected = member.workspace.id),
                ),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 12),
            Text(
              context.tr(
                'Switching loads the selected workspace and its permissions.',
              ),
            ),
            if (_error != null)
              Text(
                context.tr(_error!),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }
}
