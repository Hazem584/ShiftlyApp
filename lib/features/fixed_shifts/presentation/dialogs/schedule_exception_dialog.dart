import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/schedule_exception_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/dialogs/schedule_exception_form_content.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_dialog.dart';
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

  Future<void> _pickDate() async {
    final min = _firstDate().add(
      Duration(days: widget.employeeMembershipId == null ? 1 : 0),
    );
    final picked = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(min) ? min : _date,
      firstDate: min,
      lastDate: DateTime(min.year + 5, 12, 31),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (!widget.isCurrent()) return Navigator.pop(context);
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
    setState(() => (_busy = true, _error = null));
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
        setState(
          () => (_busy = false, _error = ApiErrorParser.parse(e).message),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: ManagerDialog(
      title: Text(
        context.tr(
          widget.employeeMembershipId == null
              ? 'Workspace holiday'
              : 'New day exception',
        ),
      ),
      content: buildScheduleExceptionFormContent(
        context: context,
        formKey: _form,
        employeeMembershipId: widget.employeeMembershipId,
        kind: _kind,
        dateKey: _dateKey,
        timezone: widget.timezone,
        templates: widget.templates,
        templateId: _templateId,
        reason: _reason,
        error: _error,
        busy: _busy,
        onKindChanged: (v) => setState(() => _kind = v),
        onPickDate: _pickDate,
        onTemplateChanged: (v) => setState(() => _templateId = v),
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
