import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/models/employee.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_compensation_card.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_details_header.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_information_sections.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_schedule_cards.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_status_action.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_work_section.dart';

class EmployeeDetailsLoadedBody extends StatelessWidget {
  const EmployeeDetailsLoadedBody({
    required this.employee,
    required this.workspaceId,
    required this.membershipId,
    required this.timezone,
    super.key,
  });

  final Employee employee;
  final String workspaceId;
  final String membershipId;
  final String timezone;

  @override
  Widget build(BuildContext context) {
    final active = employee.employmentStatus == EmploymentStatus.active;
    final suspended = employee.employmentStatus == EmploymentStatus.suspended;
    return ListView(
      key: const Key('employee-details-content'),
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
      children: [
        EmployeeDetailsHeader(employee: employee),
        const SizedBox(height: AppSpacing.l),
        EmployeeContactSection(employee: employee),
        const SizedBox(height: AppSpacing.l),
        EmployeeWorkSection(employee: employee),
        const SizedBox(height: AppSpacing.l),
        EmployeeCompensationCard(
          employee: employee,
          workspaceId: workspaceId,
          membershipId: membershipId,
          canEdit: active,
        ),
        const SizedBox(height: AppSpacing.l),
        ...buildEmployeeScheduleCards(
          context,
          employee: employee,
          workspaceId: workspaceId,
          membershipId: membershipId,
          timezone: timezone,
          canEdit: active,
        ),
        if (active || suspended)
          FilledButton.tonalIcon(
            key: Key(active ? 'deactivate-employee' : 'reactivate-employee'),
            onPressed: () => changeEmployeeMembershipStatus(
              context,
              workspaceId: workspaceId,
              membershipId: membershipId,
              employee: employee,
            ),
            icon: Icon(
              active ? Icons.person_off_outlined : Icons.person_add_alt_rounded,
            ),
            label: Text(
              context.tr(
                active ? 'Deactivate employee' : 'Reactivate employee',
              ),
            ),
          ),
      ],
    );
  }
}
