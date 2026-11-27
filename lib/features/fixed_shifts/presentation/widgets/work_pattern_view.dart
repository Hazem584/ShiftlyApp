import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/assignment_form.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/work_pattern_current_section.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/work_pattern_history_section.dart';

class WorkPatternView extends StatelessWidget {
  const WorkPatternView({
    super.key,
    required this.workspaceId,
    required this.timezone,
    required this.canEdit,
  });
  final String workspaceId;
  final String timezone;
  final bool canEdit;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<WorkPatternCubit, WorkPatternState>(
        builder: (context, state) {
          if (state.loading && state.history == null) {
            return const SurfaceCard(child: AppContentLoading());
          }
          return SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...buildWorkPatternCurrentSection(context, state),
                ...buildWorkPatternHistorySection(context, state, timezone),
                ...buildWorkPatternFooterSection(
                  context: context,
                  state: state,
                  timezone: timezone,
                  canEdit: canEdit,
                  onReplace: () => _replace(context),
                ),
              ],
            ),
          );
        },
      );

  Future<void> _replace(BuildContext context) => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AssignmentForm(
      repository: getIt.isRegistered<FixedShiftRepository>()
          ? getIt<FixedShiftRepository>()
          : context.read<FixedShiftRepository>(),
      cubit: context.read<WorkPatternCubit>(),
      workspaceId: workspaceId,
      timezone: timezone,
    ),
  );
}
