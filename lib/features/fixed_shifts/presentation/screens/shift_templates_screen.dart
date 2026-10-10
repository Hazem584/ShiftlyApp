import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/dialogs/shift_template_editor_dialog.dart';
import 'package:shiftly/features/fixed_shifts/presentation/utils/shift_templates_formatters.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/shift_template_card.dart';

class ShiftTemplatesScreen extends StatelessWidget {
  const ShiftTemplatesScreen({this.workspaceName, this.timezone, super.key});

  final String? workspaceName;
  final String? timezone;

  @override
  Widget build(BuildContext context) {
    final workspace = workspaceName == null && timezone == null
        ? context.watch<SessionCoordinator>().state.activeMembership?.workspace
        : null;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Fixed shift templates')),
        actions: [
          IconButton(
            tooltip: context.tr('Create template'),
            onPressed: () => _openEditor(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: BlocConsumer<ManagerTemplatesCubit, ManagerTemplatesState>(
        listenWhen: (a, b) => a.failure != b.failure && b.failure != null,
        listener: (context, state) => ToastService.error(
          context,
          message: shiftTemplatesScreenSupportMessage(
            state.failure!.message,
            state.failure!.requestId,
          ),
        ),
        builder: (context, state) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
              child: SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(child: Icon(Icons.schedule_rounded)),
                        const SizedBox(width: AppSpacing.m),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                workspaceName ??
                                    workspace?.name ??
                                    context.tr('Current workspace'),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                context.tr(
                                  '{value1} • {value2} active templates',
                                  {
                                    'value1':
                                        (timezone ??
                                                workspace?.timezone ??
                                                'Etc/UTC')
                                            .toString(),
                                    'value2':
                                        (state.templates
                                                .where((item) => item.active)
                                                .length)
                                            .toString(),
                                  },
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilterChip(
                        key: const Key('show-archived-templates'),
                        label: Text(context.tr('Archived')),
                        selected: state.includeArchived,
                        onSelected: (value) => context
                            .read<ManagerTemplatesCubit>()
                            .load(includeArchived: value),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(child: _body(context, state)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(context.tr('New template')),
      ),
    );
  }

  Widget _body(BuildContext context, ManagerTemplatesState state) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.templates.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            context.read<ManagerTemplatesCubit>().load(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            EmptyState(
              icon: state.failure == null
                  ? Icons.schedule_outlined
                  : Icons.cloud_off_outlined,
              title: state.failure == null
                  ? 'No fixed shifts yet'
                  : 'Templates unavailable',
              message:
                  state.failure?.message ??
                  'Create one reusable schedule for many employees.',
              action: state.failure == null
                  ? null
                  : FilledButton(
                      onPressed: () =>
                          context.read<ManagerTemplatesCubit>().load(),
                      child: Text(context.tr('Retry')),
                    ),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () =>
          context.read<ManagerTemplatesCubit>().load(refresh: true),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          final cardWidth = wide
              ? (constraints.maxWidth - 48) / 2
              : constraints.maxWidth - 36;
          return ListView(
            key: const Key('shift-template-list'),
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              18,
              4,
              18,
              160 + MediaQuery.viewPaddingOf(context).bottom,
            ),
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final template in state.templates)
                    SizedBox(
                      width: cardWidth,
                      child: ShiftTemplateCard(
                        template: template,
                        busy: state.archivingId == template.id,
                        onEdit: () => _openEditor(context, template),
                        onArchive: () => _archive(context, template),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context, [
    ShiftTemplate? template,
  ]) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<ManagerTemplatesCubit>(),
        child: ShiftTemplateEditorDialog(template: template),
      ),
    );
  }

  Future<void> _archive(BuildContext context, ShiftTemplate template) async {
    if (!template.active) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Archive template?')),
        content: Text(
          context.tr(
            '{value1} will become read-only and remain in history. Existing attendance is preserved.',
            {'value1': (template.name).toString()},
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
    if (confirmed != true || !context.mounted) {
      return;
    }
    final result = await context.read<ManagerTemplatesCubit>().archive(
      template.id,
    );
    if (context.mounted && result == FixedShiftMutationResult.success) {
      ToastService.success(context, message: 'Template archived.');
    }
  }
}
