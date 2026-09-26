import 'package:flutter/material.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/shifts/data/shift_repository.dart';

class ShiftEditorValue {
  const ShiftEditorValue({
    required this.employeeMembershipId,
    required this.startsAt,
    required this.endsAt,
    required this.breakMinutes,
    required this.graceMinutes,
    required this.notes,
  });

  final String employeeMembershipId;
  final DateTime startsAt;
  final DateTime endsAt;
  final int breakMinutes;
  final int graceMinutes;
  final String notes;
}

class ShiftEditorDialog extends StatefulWidget {
  const ShiftEditorDialog({
    required this.employees,
    required this.timezone,
    this.initial,
    super.key,
  });

  final List<Employee> employees;
  final String timezone;
  final ShiftRecord? initial;

  @override
  State<ShiftEditorDialog> createState() => _ShiftEditorDialogState();
}

class _ShiftEditorDialogState extends State<ShiftEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late String? _employeeId;
  late DateTime _startsWall;
  late DateTime _endsWall;
  late final TextEditingController _breakMinutes;
  late final TextEditingController _graceMinutes;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _employeeId =
        initial?.employeeMembershipId ??
        (widget.employees.isEmpty ? null : widget.employees.first.id);
    final now = WorkspaceTime.inWorkspace(
      DateTime.now().toUtc(),
      widget.timezone,
    );
    _startsWall = initial == null
        ? DateTime(now.year, now.month, now.day, now.hour + 1)
        : _wall(initial.startsAt);
    _endsWall = initial == null
        ? _startsWall.add(const Duration(hours: 8))
        : _wall(initial.endsAt);
    _breakMinutes = TextEditingController(
      text: (initial?.breakMinutes ?? 30).toString(),
    );
    _graceMinutes = TextEditingController(
      text: (initial?.graceMinutes ?? 10).toString(),
    );
    _notes = TextEditingController(text: initial?.notes ?? '');
  }

  DateTime _wall(DateTime value) {
    final local = WorkspaceTime.inWorkspace(value, widget.timezone);
    return DateTime(
      local.year,
      local.month,
      local.day,
      local.hour,
      local.minute,
    );
  }

  @override
  void dispose() {
    _breakMinutes.dispose();
    _graceMinutes.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.initial == null ? 'Create shift' : 'Edit shift'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                key: const Key('shift-employee'),
                initialValue: _employeeId,
                decoration: const InputDecoration(labelText: 'Employee'),
                items: [
                  for (final employee in widget.employees)
                    DropdownMenuItem(
                      value: employee.id,
                      child: Text(employee.displayName),
                    ),
                ],
                onChanged: (value) => setState(() => _employeeId = value),
                validator: (value) =>
                    value == null ? 'Choose an active employee' : null,
              ),
              const SizedBox(height: AppSpacing.s),
              _DateTimeField(
                key: const Key('shift-start'),
                label: 'Starts',
                value: _startsWall,
                timezone: widget.timezone,
                onTap: () => _pick(starts: true),
              ),
              const SizedBox(height: AppSpacing.s),
              _DateTimeField(
                key: const Key('shift-end'),
                label: 'Ends',
                value: _endsWall,
                timezone: widget.timezone,
                onTap: () => _pick(starts: false),
              ),
              const SizedBox(height: AppSpacing.s),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      key: const Key('shift-break-minutes'),
                      controller: _breakMinutes,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Break minutes',
                      ),
                      validator: _minutesValidator,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s),
                  Expanded(
                    child: TextFormField(
                      key: const Key('shift-grace-minutes'),
                      controller: _graceMinutes,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Grace minutes',
                      ),
                      validator: _minutesValidator,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s),
              TextFormField(
                key: const Key('shift-notes'),
                controller: _notes,
                maxLength: 1000,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        key: const Key('shift-editor-submit'),
        onPressed: _submit,
        child: Text(widget.initial == null ? 'Create' : 'Save'),
      ),
    ],
  );

  String? _minutesValidator(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < 0 || parsed > 1440) {
      return 'Use 0–1440';
    }
    return null;
  }

  Future<void> _pick({required bool starts}) async {
    final current = starts ? _startsWall : _endsWall;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) return;
    final value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (starts) {
        _startsWall = value;
      } else {
        _endsWall = value;
      }
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false) || _employeeId == null) {
      return;
    }
    final startsAt = WorkspaceTime.wallTimeToUtc(
      date: _startsWall,
      hour: _startsWall.hour,
      minute: _startsWall.minute,
      timezoneName: widget.timezone,
    );
    final endsAt = WorkspaceTime.wallTimeToUtc(
      date: _endsWall,
      hour: _endsWall.hour,
      minute: _endsWall.minute,
      timezoneName: widget.timezone,
    );
    Navigator.pop(
      context,
      ShiftEditorValue(
        employeeMembershipId: _employeeId!,
        startsAt: startsAt,
        endsAt: endsAt,
        breakMinutes: int.parse(_breakMinutes.text.trim()),
        graceMinutes: int.parse(_graceMinutes.text.trim()),
        notes: _notes.text.trim(),
      ),
    );
  }
}

class _DateTimeField extends StatelessWidget {
  const _DateTimeField({
    required this.label,
    required this.value,
    required this.timezone,
    required this.onTap,
    super.key,
  });
  final String label;
  final DateTime value;
  final String timezone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.m),
    ),
    tileColor: Theme.of(context).inputDecorationTheme.fillColor,
    leading: const Icon(Icons.event_outlined),
    title: Text(label),
    subtitle: Text(
      '${value.year}-${_two(value.month)}-${_two(value.day)} '
      '${_two(value.hour)}:${_two(value.minute)} · $timezone',
    ),
  );

  String _two(int value) => value.toString().padLeft(2, '0');
}
