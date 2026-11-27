import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';
import 'package:shiftly/features/employees/presentation/cubit/employee_details_cubit.dart';
import 'package:shiftly/features/employees/presentation/cubit/employees_cubit.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_dialog.dart';

Future<void> changeEmployeeMembershipStatus(
  BuildContext context, {
  required String workspaceId,
  required String membershipId,
  required Employee employee,
}) async {
  final suspending = employee.employmentStatus == EmploymentStatus.active;
  if (suspending) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => ManagerDialog(
        title: Text(context.tr('Deactivate employee?')),
        content: Text(
          context.tr('The employee will lose active workspace access.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            key: const Key('confirm-deactivate-employee'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('Deactivate')),
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
