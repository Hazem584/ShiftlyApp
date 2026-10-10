import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/routing/app_routes.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';
import 'package:shiftly/features/employees/presentation/cubit/employee_details_cubit.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_cubit.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_details_header.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_details_loading.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_information_sections.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_work_section.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/extra_shifts_section.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/work_pattern_section.dart';

class EmployeeDetailsView extends StatelessWidget {
  const EmployeeDetailsView({
    super.key,
    required this.workspaceId,
    required this.membershipId,
    required this.timezone,
  });
  final String workspaceId;
  final String membershipId;
  final String timezone;

  Future<void> _changeStatus(BuildContext context, Employee employee) async {
    final suspending = employee.employmentStatus == EmploymentStatus.active;
    if (suspending) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Deactivate employee?'),
          content: const Text(
            'The employee will lose active workspace access.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.tr('Cancel')),
            ),
            FilledButton(
              key: const Key('confirm-deactivate-employee'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Deactivate'),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
    }
    final result = await context.read<EmployeesCubit>().setStatus(
      membershipId,
      suspending ? EmployeeStatusFilter.suspended : EmployeeStatusFilter.active,
    );
    if (!context.mounted) return;
    if (result == EmployeeOperationResult.success) {
      await context.read<EmployeeDetailsCubit>().load(
        workspaceId: workspaceId,
        membershipId: membershipId,
        retain: true,
      );
      if (context.mounted) {
        ToastService.success(
          context,
          message: suspending ? 'Employee deactivated' : 'Employee reactivated',
        );
      }
    } else if (result == EmployeeOperationResult.failure) {
      ToastService.error(context, message: 'Could not update employee status.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('Employee details'))),
    body: BlocBuilder<EmployeeDetailsCubit, EmployeeDetailsState>(
      builder: (context, state) => switch (state) {
        EmployeeDetailsLoadingState() => const EmployeeDetailsLoading(),
        EmployeeDetailsErrorState(:final message) => EmptyState(
          icon: Icons.person_search_outlined,
          title: 'Employee unavailable',
          message: message,
          action: FilledButton(
            onPressed: () => context.read<EmployeeDetailsCubit>().load(
              workspaceId: workspaceId,
              membershipId: membershipId,
            ),
            child: Text(context.tr('Retry')),
          ),
        ),
        EmployeeDetailsLoadedState(:final employee) => ListView(
          key: const Key('employee-details-content'),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
          children: [
            EmployeeDetailsHeader(employee: employee),
            ListTile(
              key: const Key('employee-performance-link'),
              leading: const Icon(Icons.insights_outlined),
              title: const Text('Employee Performance'),
              onTap: () =>
                  context.push(AppRoutes.employeePerformance(membershipId)),
            ),
            const SizedBox(height: AppSpacing.l),
            EmployeeContactSection(employee: employee),
            const SizedBox(height: AppSpacing.l),
            EmployeeWorkSection(employee: employee),
            const SizedBox(height: AppSpacing.l),
            WorkPatternSection(
              workspaceId: workspaceId,
              membershipId: membershipId,
              timezone: timezone,
              canEdit: employee.employmentStatus == EmploymentStatus.active,
            ),
            const SizedBox(height: AppSpacing.l),
            ExtraShiftsSection(
              workspaceId: workspaceId,
              membershipId: membershipId,
              timezone: timezone,
              canEdit: employee.employmentStatus == EmploymentStatus.active,
            ),
            const SizedBox(height: AppSpacing.l),
            if (employee.employmentStatus == EmploymentStatus.active ||
                employee.employmentStatus == EmploymentStatus.suspended)
              FilledButton.tonalIcon(
                key: Key(
                  employee.employmentStatus == EmploymentStatus.active
                      ? 'deactivate-employee'
                      : 'reactivate-employee',
                ),
                onPressed: () => _changeStatus(context, employee),
                icon: Icon(
                  employee.employmentStatus == EmploymentStatus.active
                      ? Icons.person_off_outlined
                      : Icons.person_add_alt_rounded,
                ),
                label: Text(
                  employee.employmentStatus == EmploymentStatus.active
                      ? 'Deactivate employee'
                      : 'Reactivate employee',
                ),
              ),
          ],
        ),
      },
    ),
  );
}
