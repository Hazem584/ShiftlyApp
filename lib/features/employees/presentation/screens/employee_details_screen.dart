import 'package:flutter/material.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/extra_shifts_section.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/routing/app_routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/features/employees/data/employee_repository.dart';
import 'package:shiftly/features/employees/presentation/cubit/employee_details_cubit.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_cubit.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_details_header.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_details_loading.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_information_sections.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/work_pattern_section.dart';

part 'parts/employee_details_screen/private_employee_details_view.dart';

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
      child: _EmployeeDetailsView(
        workspaceId: resolvedWorkspaceId,
        membershipId: employeeId,
        timezone: timezone,
      ),
    );
  }
}
