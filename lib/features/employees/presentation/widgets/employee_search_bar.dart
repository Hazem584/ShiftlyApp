import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';

class EmployeeSearchBar extends StatelessWidget {
  const EmployeeSearchBar({
    required this.onChanged,
    this.status,
    this.onStatusChanged,
    super.key,
  });
  final ValueChanged<String> onChanged;
  final EmployeeStatusFilter? status;
  final ValueChanged<EmployeeStatusFilter?>? onStatusChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
    child: Column(
      children: [
        TextField(
          key: const Key('employee-search'),
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            hintText: context.tr('Search by name or email'),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<EmployeeStatusFilter?>(
          key: const Key('employee-status-filter'),
          initialValue: status,
          decoration: InputDecoration(labelText: context.tr('Employee status')),
          onChanged: onStatusChanged,
          items: [
            DropdownMenuItem(
              value: null,
              child: Text(context.tr('All statuses')),
            ),
            DropdownMenuItem(
              value: EmployeeStatusFilter.active,
              child: Text(context.tr('Active')),
            ),
            DropdownMenuItem(
              value: EmployeeStatusFilter.suspended,
              child: Text(context.tr('Suspended')),
            ),
          ],
        ),
      ],
    ),
  );
}
