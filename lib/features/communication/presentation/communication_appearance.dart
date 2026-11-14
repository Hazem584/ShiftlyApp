import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/employee_design.dart';

class CommunicationAppearance extends StatelessWidget {
  const CommunicationAppearance({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final theme = EmployeeDesign.applies(context)
        ? Theme.of(context)
        : EmployeeDesign.theme(
            Theme.of(context),
            arabic: Localizations.localeOf(context).languageCode == 'ar',
          );
    return Theme(
      data: theme.copyWith(
        listTileTheme: theme.listTileTheme.copyWith(
          minVerticalPadding: 0,
          titleTextStyle: theme.textTheme.titleMedium,
          subtitleTextStyle: theme.textTheme.bodySmall,
          iconColor: theme.colorScheme.onSurfaceVariant,
        ),
        iconTheme: IconThemeData(color: theme.colorScheme.onSurfaceVariant),
      ),
      child: child,
    );
  }
}
