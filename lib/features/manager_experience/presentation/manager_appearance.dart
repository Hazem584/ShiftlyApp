import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/employee_design.dart';
import 'package:shiftly/core/theme/manager_design.dart';

export 'package:shiftly/core/theme/manager_design.dart';

class ManagerAppearance extends StatelessWidget {
  const ManagerAppearance({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final theme = EmployeeDesign.theme(
      Theme.of(context),
      arabic: Localizations.localeOf(context).languageCode == 'ar',
    );
    return Theme(
      data: theme.copyWith(
        chipTheme: theme.chipTheme.copyWith(
          secondaryLabelStyle: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        extensions: [...theme.extensions.values, const ManagerDesign()],
      ),
      child: child,
    );
  }
}
