import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';
import 'package:shiftly/features/employees/presentation/cubit/employee_details_cubit.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_details_view.dart';

class EmployeeDetailsScreen extends StatelessWidget {
  const EmployeeDetailsScreen({required this.employeeId, super.key});
  final String employeeId;

  @override
  Widget build(BuildContext context) {
    String? workspaceId;
    var timezone = 'Etc/UTC';
    try {
      final workspace = context
          .read<SessionCoordinator>()
          .state
          .activeMembership
          ?.workspace;
      workspaceId = workspace?.id;
      timezone = workspace?.timezone ?? timezone;
    } catch (_) {
      workspaceId = 'preview';
    }
    if (workspaceId == null) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.lock_outline,
          title: 'Workspace unavailable',
          message: 'Select an active manager workspace and try again.',
        ),
      );
    }
    final resolvedWorkspaceId = workspaceId;
    return BlocProvider(
      create: (_) =>
          (getIt.isRegistered<EmployeeDetailsCubit>()
                ? getIt<EmployeeDetailsCubit>()
                : EmployeeDetailsCubit(context.read<EmployeeRepository>()))
            ..load(workspaceId: resolvedWorkspaceId, membershipId: employeeId),
      child: EmployeeDetailsView(
        workspaceId: resolvedWorkspaceId,
        membershipId: employeeId,
        timezone: timezone,
      ),
    );
  }
}
