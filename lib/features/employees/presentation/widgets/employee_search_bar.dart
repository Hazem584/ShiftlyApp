import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/employees/domain/repositories/employee_repository.dart';
import 'package:shiftly/features/employees/presentation/widgets/employee_status_filter_chips.dart';

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
          child: EmployeeStatusFilterChips(
            onShift: onShift,
            status: status,
            onShiftChanged: onShiftChanged,
            onStatusChanged: onStatusChanged,
          ),
        ),
      ],
    ),
  );
}
