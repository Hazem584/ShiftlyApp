import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/schedule_exception_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/work_location_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/screens/shift_templates_actions.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/schedule_exceptions_section.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/shift_template_card.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/work_locations_section.dart';

Widget buildShiftTemplatesBody(
  BuildContext context,
  ManagerTemplatesState state,
) {
  final templates = state.templates
      .where((t) => state.includeArchived ? !t.active : t.active)
      .toList();
  if (state.loading) return const AppContentLoading();
  final holidays = _buildWorkspaceHolidays(context);
  if (templates.isEmpty) {
    return buildShiftTemplatesEmptyView(context, state, holidays);
  }
  return RefreshIndicator(
    onRefresh: () => context.read<ManagerTemplatesCubit>().load(refresh: true),
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
            holidays,
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
                      onEdit: () => openShiftTemplateEditor(context, template),
                      onArchive: () =>
                          confirmArchiveShiftTemplate(context, template),
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

Widget _buildWorkspaceHolidays(BuildContext context) {
  final cubit = context.read<ManagerTemplatesCubit>();
  final scope = cubit.scope;
  final widgets = <Widget>[
    if (scope != null && getIt.isRegistered<WorkLocationRepository>()) ...[
      WorkLocationsSection(
        key: ValueKey(('work-locations', scope)),
        scope: scope,
        repository: getIt<WorkLocationRepository>(),
        isCurrent: () => cubit.scope == scope,
        onChanged: () => cubit.load(refresh: true),
      ),
      const SizedBox(height: 12),
    ],
    if (scope != null && getIt.isRegistered<ScheduleExceptionRepository>())
      ScheduleExceptionsSection(
        key: ValueKey(('holidays', scope)),
        scope: scope,
        repository: getIt<ScheduleExceptionRepository>(),
        fixedShifts: getIt<FixedShiftRepository>(),
        isCurrent: () => cubit.scope == scope,
        onChanged: () => cubit.load(refresh: true),
      ),
  ];
  return widgets.isEmpty
      ? const SizedBox.shrink()
      : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widgets,
        );
}
