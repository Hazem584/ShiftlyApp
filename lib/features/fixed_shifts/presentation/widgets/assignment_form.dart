import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/utils/active_templates_loader.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/assignment_form_content.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_dialog.dart';

class AssignmentForm extends StatefulWidget {
  const AssignmentForm({
    required this.repository,
    required this.cubit,
    required this.workspaceId,
    required this.timezone,
    super.key,
  });
  final FixedShiftRepository repository;
  final WorkPatternCubit cubit;
  final String workspaceId, timezone;
  @override
  State<AssignmentForm> createState() => _AssignmentFormState();
}

class _AssignmentFormState extends State<AssignmentForm> {
  final days = <int>{};
  late DateTime date, today;
  List<ShiftTemplate>? templates;
  String? templateId, error;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    final local = WorkspaceTime.inWorkspace(
      DateTime.now().toUtc(),
      widget.timezone,
    );
    date = today = DateTime(local.year, local.month, local.day);
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await loadActiveWorkspaceTemplates(
        widget.repository,
        widget.workspaceId,
        isMounted: () => mounted,
      );
      if (mounted) setState(() => (templates = result, error = null));
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Unable to load active templates. Retry.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => ManagerDialog(
    title: Text(context.tr('Assign a fixed shift')),
    scrollable: true,
    content: buildAssignmentFormContent(
      context: context,
      timezone: widget.timezone,
      busy: busy,
      templates: templates,
      templateId: templateId,
      days: days,
      date: date,
      error: error,
      onLoadTemplates: _load,
      onTemplateChanged: (v) => setState(() => templateId = v),
      onDayToggled: (d, sel) =>
          setState(() => sel ? days.add(d) : days.remove(d)),
      onPickDate: _pickDate,
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: Text(context.tr('Cancel')),
      ),
      FilledButton(
        onPressed: busy || days.isEmpty || templateId == null ? null : _submit,
        child: Text(
          busy ? context.tr('Saving…') : context.tr('Review replacement'),
        ),
      ),
    ],
  );

  Future<void> _pickDate() async {
    final local = WorkspaceTime.inWorkspace(
      DateTime.now().toUtc(),
      widget.timezone,
    );
    today = DateTime(local.year, local.month, local.day);
    final chosen = await showDatePicker(
      context: context,
      initialDate: date.isBefore(today) ? today : date,
      firstDate: today,
      lastDate: DateTime(today.year + 5, 12, 31),
    );
    if (mounted && chosen != null) setState(() => date = chosen);
  }

  Future<void> _submit() async {
    final key = WorkspaceTime.localDateKey(
      year: date.year,
      month: date.month,
      day: date.day,
    );
    final confirmed = await showConfirmAssignmentDialog(
      context: context,
      templateName: templates!.firstWhere((v) => v.id == templateId).name,
      dateKey: key,
      timezone: widget.timezone,
    );
    if (!mounted || confirmed != true || widget.cubit.isClosed) return;
    setState(() => (busy = true, error = null));
    final result = await widget.cubit.replace(
      shiftTemplateId: templateId!,
      weekdays: days,
      effectiveFrom: key,
    );
    if (!mounted) return;
    if (result == FixedShiftMutationResult.success) {
      return Navigator.pop(context, true);
    }
    setState(() {
      busy = false;
      error =
          widget.cubit.state.failure?.message ??
          'Unable to save assignment. Your selections are retained.';
    });
  }
}
