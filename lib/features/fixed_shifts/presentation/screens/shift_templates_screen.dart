import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/offline/read_sync_banner.dart';
import 'package:shiftly/core/offline/read_sync_state.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/screens/shift_templates_actions.dart';
import 'package:shiftly/features/fixed_shifts/presentation/screens/shift_templates_body.dart';
import 'package:shiftly/features/fixed_shifts/presentation/utils/shift_templates_formatters.dart';

class ShiftTemplatesScreen extends StatelessWidget {
  const ShiftTemplatesScreen({this.workspaceName, this.timezone, super.key});

  final String? workspaceName;
  final String? timezone;

  @override
  Widget build(BuildContext context) => Scaffold(
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
          Expanded(child: buildShiftTemplatesBody(context, state)),
        ],
      ),
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: FilledButton(
          key: const Key('create-shift-template'),
          onPressed: () => openShiftTemplateEditor(context),
          child: Text(context.tr('Create template')),
        ),
      ),
    ),
  );
}
