import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/dialogs/shift_template_editor_dialog.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_dialog.dart';

Widget buildShiftTemplatesEmptyView(
  BuildContext context,
  ManagerTemplatesState state,
  Widget holidays,
) => RefreshIndicator(
  onRefresh: () => context.read<ManagerTemplatesCubit>().load(refresh: true),
  child: ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      EmptyState(
        icon: state.failure == null
            ? Icons.schedule_outlined
            : Icons.cloud_off_outlined,
        title: state.failure == null
            ? state.includeArchived
                  ? 'No archived templates'
                  : 'No fixed shifts yet'
            : 'Templates unavailable',
        message:
            state.failure?.message ??
            'Create one reusable schedule for many employees.',
        action: state.failure == null
            ? null
            : FilledButton(
                onPressed: () => context.read<ManagerTemplatesCubit>().load(),
                child: Text(context.tr('Retry')),
              ),
      ),
      Padding(padding: const EdgeInsets.all(18), child: holidays),
    ],
  ),
);

Future<void> openShiftTemplateEditor(
  BuildContext context, [
  ShiftTemplate? template,
]) => showDialog<void>(
  context: context,
  barrierDismissible: false,
  builder: (_) => BlocProvider.value(
    value: context.read<ManagerTemplatesCubit>(),
    child: ShiftTemplateEditorDialog(template: template),
  ),
);

Future<void> confirmArchiveShiftTemplate(
  BuildContext context,
  ShiftTemplate template,
) async {
  if (!template.active) return;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => ManagerDialog(
      title: Text(context.tr('Archive template?')),
      content: Text(
        context.tr(
          '{value1} will become read-only and remain in history. Existing attendance is preserved.',
          {'value1': template.name},
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(context.tr('Keep active')),
        ),
        FilledButton(
          key: const Key('confirm-archive-template'),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(context.tr('Archive')),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final result = await context.read<ManagerTemplatesCubit>().archive(
    template.id,
  );
  if (context.mounted && result == FixedShiftMutationResult.success) {
    ToastService.success(context, message: 'Template archived.');
  }
}
