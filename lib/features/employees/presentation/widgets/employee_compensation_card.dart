import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/features/employees/presentation/dialogs/employee_compensation_dialog.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_detail.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_information_section.dart';

class EmployeeCompensationCard extends StatelessWidget {
  const EmployeeCompensationCard({
    super.key,
    required this.employee,
    required this.workspaceId,
    required this.membershipId,
    required this.canEdit,
  });

  final Employee employee;
  final String workspaceId;
  final String membershipId;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final monthly = employee.monthlySalary;
    final rate = employee.hourlyRate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EmployeeInformationSection(
          title: context.tr('Salary & hourly rate'),
          rows: [
            EmployeeDetail(
              icon: Icons.payments_outlined,
              title: context.tr('Monthly salary'),
              value: monthly != null
                  ? monthly.toStringAsFixed(2)
                  : context.tr('Not set'),
            ),
            EmployeeDetail(
              icon: Icons.timer_outlined,
              title: context.tr('Overtime hourly rate'),
              value: rate?.toStringAsFixed(2) ?? context.tr('Not set'),
            ),
            EmployeeDetail(
              icon: Icons.calendar_today_outlined,
              title: context.tr('Payroll workdays per month'),
              value: employee.payrollWorkDays.toString(),
            ),
            EmployeeDetail(
              icon: Icons.payments_outlined,
              title: context.tr('Daily rate'),
              value:
                  employee.dailyRate?.toStringAsFixed(2) ??
                  context.tr('Not set'),
            ),
          ],
        ),
        if (canEdit)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              key: const Key('edit-employee-compensation'),
              onPressed: () => showEmployeeCompensationDialog(
                context,
                workspaceId: workspaceId,
                membershipId: membershipId,
                employee: employee,
              ),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(context.tr('Edit salary & rate')),
            ),
          ),
      ],
    );
  }
}
