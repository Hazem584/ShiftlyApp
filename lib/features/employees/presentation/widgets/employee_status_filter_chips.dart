import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';

class EmployeeStatusFilterChips extends StatelessWidget {
  const EmployeeStatusFilterChips({
    required this.onShift,
    this.status,
    this.onShiftChanged,
    this.onStatusChanged,
    super.key,
  });

  final bool onShift;
  final EmployeeStatusFilter? status;
  final ValueChanged<bool>? onShiftChanged;
  final ValueChanged<EmployeeStatusFilter?>? onStatusChanged;

  @override
  Widget build(BuildContext context) => Wrap(
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
  );
}
