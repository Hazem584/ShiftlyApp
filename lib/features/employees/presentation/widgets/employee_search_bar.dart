import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';

class EmployeeSearchBar extends StatelessWidget {
  const EmployeeSearchBar({
    required this.onChanged,
    this.status,
    this.onShift = false,
    this.onShiftChanged,
    this.onStatusChanged,
    super.key,
  });
  final ValueChanged<String> onChanged;
  final bool onShift;
  final ValueChanged<bool>? onShiftChanged;
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
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Wrap(
            key: const Key('employee-status-filter'),
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(context.tr('All')),
                selected: status == null && !onShift,
                onSelected: (_) {
                  onShiftChanged?.call(false);
                  onStatusChanged?.call(null);
                },
              ),
              ChoiceChip(
                label: Text(context.tr('On shift')),
                selected: onShift,
                onSelected: (value) {
                  onShiftChanged?.call(value);
                  onStatusChanged?.call(null);
                },
              ),
              ChoiceChip(
                label: Text(context.tr('Inactive')),
                selected: status == EmployeeStatusFilter.suspended,
                onSelected: (_) {
                  onShiftChanged?.call(false);
                  onStatusChanged?.call(EmployeeStatusFilter.suspended);
                },
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
