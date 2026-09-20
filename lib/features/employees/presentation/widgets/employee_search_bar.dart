import 'package:flutter/material.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/theme/app_colors.dart';

class EmployeeSearchBar extends StatelessWidget {
  const EmployeeSearchBar({required this.onChanged, super.key});
  final ValueChanged<String> onChanged;

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
          child: OutlinedButton(
            onPressed: () => ToastService.info(
              context,
              message: 'More filters are coming soon',
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.zero,
              backgroundColor: AppColors.surface,
            ),
            child: const Icon(Icons.tune_rounded, size: 20),
          ),
        ),
      ],
    ),
  );
}
