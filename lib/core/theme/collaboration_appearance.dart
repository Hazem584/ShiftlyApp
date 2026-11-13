import 'package:flutter/material.dart';

import 'employee_design.dart';

/// Shared Penpot appearance for personal tasks and workspace conversations.
class CollaborationAppearance extends StatelessWidget {
  const CollaborationAppearance({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => EmployeeDesign.applies(context)
      ? child
      : Theme(
          data: EmployeeDesign.theme(
            Theme.of(context),
            arabic: Localizations.localeOf(context).languageCode == 'ar',
          ),
          child: child,
        );
}
