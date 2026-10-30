import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/features/attendance/presentation/cubit/attendance_calendar_cubit.dart';
import 'package:shiftly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/schedule_exception_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/schedule_exceptions_section.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/work_pattern_view.dart';

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
  Widget build(BuildContext context) {
    final manager = context.watch<ManagerTemplatesCubit>();
    final scope = manager.scope;
    if (scope == null || !scope.isManager || scope.workspaceId != workspaceId) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BlocProvider(
          key: ValueKey((scope, membershipId, canEdit)),
          create: (_) =>
              WorkPatternCubit(
                getIt.isRegistered<FixedShiftRepository>()
                    ? getIt<FixedShiftRepository>()
                    : context.read<FixedShiftRepository>(),
                onChanged: () {
                  if (!context.mounted || manager.scope != scope) return;
                  manager.load(refresh: true);
                  context.read<DashboardCubit>().invalidate();
                  context.read<AttendanceCalendarCubit>().invalidate();
                },
              )..bind(
                workspaceId: workspaceId,
                membershipId: membershipId,
                scope: scope,
              ),
          child: WorkPatternView(
            workspaceId: workspaceId,
            timezone: timezone,
            canEdit: canEdit,
          ),
        ),
        if (getIt.isRegistered<ScheduleExceptionRepository>()) ...[
          const SizedBox(height: 12),
          ScheduleExceptionsSection(
            key: ValueKey(('exceptions', scope, membershipId)),
            scope: scope,
            employeeMembershipId: membershipId,
            canEdit: canEdit,
            repository: getIt<ScheduleExceptionRepository>(),
            fixedShifts: getIt<FixedShiftRepository>(),
            isCurrent: () => manager.scope == scope,
            onChanged: () {
              if (!context.mounted || manager.scope != scope) return;
              manager.load(refresh: true);
              context.read<DashboardCubit>().invalidate();
              context.read<AttendanceCalendarCubit>().invalidate();
            },
          ),
        ],
      ],
    );
  }
}
