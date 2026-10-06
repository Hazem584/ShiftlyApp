import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/fixed_shifts/data/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';

part 'parts/work_pattern_section/private_work_pattern_view.dart';
part 'parts/work_pattern_section/private_pattern_dialog.dart';
part 'parts/work_pattern_section/private_pattern_dialog_state.dart';
part 'parts/work_pattern_section/private_weekday_row.dart';

class WorkPatternSection extends StatelessWidget {
  const WorkPatternSection({
    required this.workspaceId,
    required this.membershipId,
    required this.timezone,
    required this.canEdit,
    super.key,
  });
  final String workspaceId;
  final String membershipId;
  final String timezone;
  final bool canEdit;

  @override
  Widget build(BuildContext context) => BlocProvider(
    key: ValueKey('$workspaceId|$membershipId|$canEdit'),
    create: (context) =>
        (getIt.isRegistered<WorkPatternCubit>()
              ? getIt<WorkPatternCubit>()
              : WorkPatternCubit(context.read<FixedShiftRepository>()))
          ..bind(workspaceId: workspaceId, membershipId: membershipId),
    child: _WorkPatternView(timezone: timezone, canEdit: canEdit),
  );
}

String _dateKey(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
