import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/extra_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/utils/active_templates_loader.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/extra_shift_form_fields.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/extra_shift_form_submitter.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_dialog.dart';

class ExtraShiftForm extends StatefulWidget {
  const ExtraShiftForm({
    required this.repository,
    required this.cubit,
    required this.workspaceId,
    required this.timezone,
    required this.actual,
    super.key,
  });
  final FixedShiftRepository repository;
  final ExtraShiftsCubit cubit;
  final String workspaceId, timezone;
  final bool actual;
  @override
  State<ExtraShiftForm> createState() => _ExtraShiftFormState();
}

class _ExtraShiftFormState extends State<ExtraShiftForm> {
  final explanation = TextEditingController(),
      actualIn = TextEditingController(),
      actualOut = TextEditingController();
  String reason = 'ADDITIONAL_SHIFT';
  String? templateId, error;
  List<ShiftTemplate>? templates;
  late DateTime date;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    final t = WorkspaceTime.inWorkspace(
      DateTime.now().toUtc(),
      widget.timezone,
    );
    date = DateTime(t.year, t.month, t.day);
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final res = await loadActiveWorkspaceTemplates(
        widget.repository,
        widget.workspaceId,
        isMounted: () => mounted,
      );
      if (mounted) setState(() => (templates = res, error = null));
    } catch (_) {
      if (mounted) {
        setState(() => error = 'Unable to load active templates. Retry.');
      }
    }
  }

  @override
  void dispose() {
    for (final c in [explanation, actualIn, actualOut]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ManagerDialog(
    title: Text(
      widget.actual
          ? context.tr('Record extra attendance')
          : context.tr('Authorize an extra shift'),
    ),
    scrollable: true,
    content: buildExtraShiftFormContent(
      context: context,
      timezone: widget.timezone,
      actual: widget.actual,
      busy: busy,
      hasIntent: widget.cubit.state.intent != null,
      templates: templates,
      templateId: templateId,
      date: date,
      reason: reason,
      error: error,
      explanation: explanation,
      actualIn: actualIn,
      actualOut: actualOut,
      onLoadTemplates: _loadTemplates,
      onTemplateChanged: (v) => setState(() => templateId = v),
      onPickDate: _pickDate,
      onReasonChanged: (v) => setState(() => reason = v),
      onRecover: () => recoverExtraShiftOperation(
        context: context,
        cubit: widget.cubit,
        isMounted: () => mounted,
        updateState: (b, e) => setState(() => (busy = b, error = e)),
      ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: Text(context.tr('Cancel')),
      ),
      FilledButton(
        onPressed:
            busy || templateId == null || widget.cubit.state.recoveryBlocked
            ? null
            : () => submitExtraShiftForm(
                context: context,
                cubit: widget.cubit,
                templates: templates!,
                templateId: templateId!,
                date: date,
                reason: reason,
                explanationText: explanation.text,
                actual: widget.actual,
                actualInText: actualIn.text,
                actualOutText: actualOut.text,
                timezone: widget.timezone,
                isMounted: () => mounted,
                updateState: (b, e) => setState(() => (busy = b, error = e)),
              ),
        child: Text(
          busy ? context.tr('Saving…') : context.tr('Review and save'),
        ),
      ),
    ],
  );

  Future<void> _pickDate() async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime(date.year + 5, 12, 31),
    );
    if (mounted && chosen != null) setState(() => date = chosen);
  }
}
