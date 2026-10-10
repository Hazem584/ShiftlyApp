import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_colors.dart';
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
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            key: const Key('employee-search'),
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              hintText: context.tr('Search by name or email'),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox.square(
          dimension: 52,
          child: PopupMenuButton<EmployeeStatusFilter?>(
            key: const Key('employee-status-filter'),
            onSelected: onStatusChanged,
            tooltip: context.tr('Filter employees'),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: null,
                child: Text(context.tr('All statuses')),
              ),
              PopupMenuItem(
                value: EmployeeStatusFilter.active,
                child: Text(context.tr('Active')),
              ),
              PopupMenuItem(
                value: EmployeeStatusFilter.suspended,
                child: Text(context.tr('Suspended')),
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
