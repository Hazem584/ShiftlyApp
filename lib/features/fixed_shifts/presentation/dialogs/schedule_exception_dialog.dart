import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/schedule_exception_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/active_template_selector.dart';
import 'package:uuid/uuid.dart';

class ScheduleExceptionDialog extends StatefulWidget {
  const ScheduleExceptionDialog({
    super.key,
    required this.repository,
    required this.workspaceId,
    required this.timezone,
    required this.isCurrent,
    required this.templates,
    this.employeeMembershipId,
  });
  final ScheduleExceptionRepository repository;
  final String workspaceId, timezone;
  final String? employeeMembershipId;
  final List<ShiftTemplate> templates;
  final bool Function() isCurrent;
  @override
  State<ScheduleExceptionDialog> createState() =>
      _ScheduleExceptionDialogState();
}

class _ScheduleExceptionDialogState extends State<ScheduleExceptionDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();
  late String _kind = widget.employeeMembershipId == null ? 'HOLIDAY' : 'SHIFT';
  late DateTime _date = _firstDate().add(const Duration(days: 1));
  String? _templateId, _error, _payload, _clientId;
  bool _busy = false;
  DateTime _firstDate() {
    final local = WorkspaceTime.inWorkspace(DateTime.now(), widget.timezone);
    return DateTime(local.year, local.month, local.day);
  }

  String get _dateKey => WorkspaceTime.localDateKey(
    year: _date.year,
    month: _date.month,
    day: _date.day,
  );
  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (!widget.isCurrent()) {
      Navigator.pop(context);
      return;
    }
    final payload = jsonEncode([
      _kind,
      _dateKey,
      _kind == 'SHIFT' ? _templateId : null,
      _reason.text.trim(),
    ]);
    if (_payload != payload) {
      _payload = payload;
      _clientId = const Uuid().v4();
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.create(
        widget.workspaceId,
        clientExceptionId: _clientId!,
        kind: _kind,
        operationalDate: _dateKey,
        reason: _reason.text.trim(),
        employeeMembershipId: widget.employeeMembershipId,
        shiftTemplateId: _kind == 'SHIFT' ? _templateId : null,
      );
      if (mounted) Navigator.pop(context, widget.isCurrent());
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = ApiErrorParser.parse(e).message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Text(
        context.tr(
          widget.employeeMembershipId == null
              ? 'Workspace holiday'
              : 'New day exception',
        ),
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr(
                    'Changes apply to this date only. Recorded attendance and captured points days cannot be changed.',
                  ),
                ),
                const SizedBox(height: 12),
                if (widget.employeeMembershipId != null)
                  DropdownButtonFormField<String>(
                    initialValue: _kind,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: context.tr('Exception type'),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'SHIFT',
                        child: Text(context.tr('One-day shift change')),
                      ),
                      DropdownMenuItem(
                        value: 'DAY_OFF',
                        child: Text(context.tr('Employee day off')),
                      ),
                    ],
                    onChanged: _busy ? null : (v) => setState(() => _kind = v!),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () async {
                          final minimum = _firstDate().add(
                            Duration(
                              days: widget.employeeMembershipId == null ? 1 : 0,
                            ),
                          );
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date.isBefore(minimum)
                                ? minimum
                                : _date,
                            firstDate: minimum,
                            lastDate: DateTime(minimum.year + 5, 12, 31),
                          );
                          if (picked != null && mounted) {
                            setState(() => _date = picked);
                          }
                        },
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text('$_dateKey · ${widget.timezone}'),
                ),
                if (_kind == 'SHIFT') ...[
                  const SizedBox(height: 12),
                  ActiveTemplateSelector(
                    templates: widget.templates,
                    value: _templateId,
                    onChanged: _busy
                        ? null
                        : (v) => setState(() => _templateId = v),
                  ),
                  if (widget.templates.isEmpty)
                    Text(
                      context.tr(
                        'Create an active fixed-shift template first.',
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reason,
                  enabled: !_busy,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: InputDecoration(labelText: context.tr('Reason')),
                  validator: (v) => (v?.trim().length ?? 0) < 5
                      ? context.tr('Enter a reason of at least 5 characters.')
                      : null,
                ),
                if (_error != null)
                  Text(
                    context.tr(_error!),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(context.tr('Cancel')),
        ),
        FilledButton(
          onPressed: _busy || (_kind == 'SHIFT' && _templateId == null)
              ? null
              : _save,
          child: Text(context.tr(_busy ? 'Saving...' : 'Save exception')),
        ),
      ],
    ),
  );
}
