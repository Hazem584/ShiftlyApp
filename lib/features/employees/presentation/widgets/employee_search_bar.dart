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
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
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
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Wrap(
            key: const Key('employee-status-filter'),
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in <(EmployeeStatusFilter?, String)>[
                (null, 'All'),
                (EmployeeStatusFilter.active, 'Active'),
                (EmployeeStatusFilter.suspended, 'Suspended'),
              ])
                ChoiceChip(
                  label: Text(context.tr(item.$2)),
                  selected: status == item.$1,
                  onSelected: onStatusChanged == null
                      ? null
                      : (_) => onStatusChanged!(item.$1),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
