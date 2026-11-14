import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/offline/read_sync_banner.dart';
import 'package:shiftly/core/offline/read_sync_state.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/schedule_exception_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/dialogs/shift_template_editor_dialog.dart';
import 'package:shiftly/features/fixed_shifts/presentation/utils/shift_templates_formatters.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/schedule_exceptions_section.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/shift_template_card.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_dialog.dart';

class ShiftTemplatesScreen extends StatelessWidget {
  const ShiftTemplatesScreen({this.workspaceName, this.timezone, super.key});

  final String? workspaceName;
  final String? timezone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('Shift templates'))),
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
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: ReadSyncBanner(
                category: ReadCategory.schedule,
                onRefresh: () =>
                    context.read<ManagerTemplatesCubit>().load(refresh: true),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('Reusable hours and attendance policies'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: Text(context.tr('Active')),
                        selected: !state.includeArchived,
                        onSelected: (_) => context
                            .read<ManagerTemplatesCubit>()
                            .load(includeArchived: false),
                      ),
                      ChoiceChip(
                        key: const Key('show-archived-templates'),
                        label: Text(context.tr('Archived')),
                        selected: state.includeArchived,
                        onSelected: (value) => context
                            .read<ManagerTemplatesCubit>()
                            .load(includeArchived: value),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(child: _body(context, state)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: FilledButton(
            key: const Key('create-shift-template'),
            onPressed: () => _openEditor(context),
            child: Text(context.tr('Create template')),
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, ManagerTemplatesState state) {
    final templates = state.templates
        .where((t) => state.includeArchived ? !t.active : t.active)
        .toList();
    if (state.loading) {
      return const AppContentLoading();
    }
    if (templates.isEmpty) {
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
                      onPressed: () =>
                          context.read<ManagerTemplatesCubit>().load(),
                      child: Text(context.tr('Retry')),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: _holidays(context),
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
              _holidays(context),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final template in templates)
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

  Widget _holidays(BuildContext context) {
    final cubit = context.read<ManagerTemplatesCubit>();
    final scope = cubit.scope;
    if (scope == null || !getIt.isRegistered<ScheduleExceptionRepository>()) {
      return const SizedBox.shrink();
    }
    return ScheduleExceptionsSection(
      key: ValueKey(('holidays', scope)),
      scope: scope,
      repository: getIt<ScheduleExceptionRepository>(),
      fixedShifts: getIt<FixedShiftRepository>(),
      isCurrent: () => cubit.scope == scope,
      onChanged: () => cubit.load(refresh: true),
    );
  }

  Future<void> _archive(BuildContext context, ShiftTemplate template) async {
    if (!template.active) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ManagerDialog(
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
