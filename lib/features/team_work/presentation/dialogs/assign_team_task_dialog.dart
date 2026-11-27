import 'package:flutter/material.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';

Future<bool> showAssignTeamTaskDialog(
  BuildContext context, {
  required String workspaceId,
}) async =>
    (await showDialog<bool>(
      context: context,
      builder: (_) => _AssignTeamTaskDialog(workspaceId: workspaceId),
    )) ??
    false;

class _AssignTeamTaskDialog extends StatefulWidget {
  const _AssignTeamTaskDialog({required this.workspaceId});
  final String workspaceId;
  @override
  State<_AssignTeamTaskDialog> createState() => _AssignTeamTaskDialogState();
}

class _AssignTeamTaskDialogState extends State<_AssignTeamTaskDialog> {
  final _title = TextEditingController();
  final _selected = <String>{};
  String _priority = 'MEDIUM';
  bool _saving = false;
  late final Future<EmployeePage> _employees = getIt<EmployeeRepository>()
      .listEmployees(
        workspaceId: widget.workspaceId,
        status: EmployeeStatusFilter.active,
        limit: 50,
      );

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty || _selected.isEmpty) return;
    setState(() => _saving = true);
    try {
      await getIt<TeamWorkRepository>().createAssignedTask(
        widget.workspaceId,
        assigneeMembershipIds: _selected.toList(),
        title: _title.text.trim(),
        priority: _priority,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ToastService.error(context, message: 'Could not assign task.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.tr('Assign task to team')),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _title,
            maxLength: 200,
            enabled: !_saving,
            decoration: InputDecoration(labelText: context.tr('Task title')),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _priority,
            decoration: InputDecoration(labelText: context.tr('Priority')),
            items: [
              for (final p in const ['LOW', 'MEDIUM', 'HIGH'])
                DropdownMenuItem(value: p, child: Text(context.tr(p))),
            ],
            onChanged: _saving
                ? null
                : (v) => setState(() => _priority = v ?? 'MEDIUM'),
          ),
          const SizedBox(height: 12),
          Text(context.tr('Select employees')),
          FutureBuilder<EmployeePage>(
            future: _employees,
            builder: (context, snap) => Wrap(
              spacing: 6,
              children: [
                if (snap.connectionState == ConnectionState.waiting)
                  const CircularProgressIndicator()
                else if (snap.hasError)
                  Text(context.tr('Could not load active workspace members.'))
                else if (snap.data?.data.any(
                      (e) => e.role == EmployeeRole.employee,
                    ) !=
                    true)
                  Text(context.tr('No active employees.')),
                for (final e in (snap.data?.data ?? const <Employee>[]).where(
                  (e) => e.role == EmployeeRole.employee,
                ))
                  FilterChip(
                    label: Text(e.displayName),
                    selected: _selected.contains(e.id),
                    selectedColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    labelStyle: TextStyle(
                      color: _selected.contains(e.id)
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    onSelected: _saving
                        ? null
                        : (v) => setState(
                            () => v
                                ? _selected.add(e.id)
                                : _selected.remove(e.id),
                          ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.of(context).pop(false),
        child: Text(context.tr('Cancel')),
      ),
      FilledButton(
        onPressed: _saving || _selected.isEmpty ? null : _submit,
        child: Text(context.tr('Assign')),
      ),
    ],
  );
}
