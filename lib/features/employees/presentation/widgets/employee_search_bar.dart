import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_colors.dart';
import 'package:shiftly/features/employees/data/employee_repository.dart';

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
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            key: const Key('employee-search'),
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded, size: 20),
              hintText: 'Search employees…',
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox.square(
          dimension: 52,
          child: PopupMenuButton<EmployeeStatusFilter?>(
            key: const Key('employee-status-filter'),
            onSelected: onStatusChanged,
            tooltip: 'Filter employees',
            itemBuilder: (_) => const [
              PopupMenuItem(value: null, child: Text('All statuses')),
              PopupMenuItem(
                value: EmployeeStatusFilter.active,
                child: Text('Active'),
              ),
              PopupMenuItem(
                value: EmployeeStatusFilter.suspended,
                child: Text('Suspended'),
              ),
            ],
            child: Icon(
              Icons.tune_rounded,
              size: 20,
              color: status == null ? null : AppColors.orange,
            ),
          ),
        ),
      ],
    ),
  );
}
