import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/attendance/presentation/cubit/attendance_calendar_cubit.dart';
import 'package:shiftly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/extra_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/extra_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/manager_templates_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/extra_shifts_view.dart';

class ExtraShiftsSection extends StatelessWidget {
  const ExtraShiftsSection({
    required this.workspaceId,
    required this.membershipId,
    required this.timezone,
    required this.canEdit,
    super.key,
  });
  final String workspaceId, membershipId, timezone;
  final bool canEdit;
  @override
  Widget build(BuildContext context) {
    final manager = context.watch<ManagerTemplatesCubit>();
    final scope = manager.scope;
    if (scope == null ||
        !scope.isManager ||
        scope.workspaceId != workspaceId ||
        !getIt.isRegistered<ExtraShiftRepository>()) {
      return const SizedBox.shrink();
    }
    return BlocProvider(
      key: ValueKey((scope, membershipId, canEdit)),
      create: (_) => ExtraShiftsCubit(
        getIt<ExtraShiftRepository>(),
        onChanged: () {
          if (!context.mounted || manager.scope != scope) return;
          manager.load(refresh: true);
          context.read<DashboardCubit>().invalidate();
          context.read<AttendanceCalendarCubit>().invalidate();
        },
      )..bind(scope, membershipId),
      child: ExtraShiftsView(
        workspaceId: workspaceId,
        timezone: timezone,
        canEdit: canEdit && WorkspaceTime.isValid(timezone),
      ),
    );
  }
}
