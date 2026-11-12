import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class EmployeePage extends StatelessWidget {
  const EmployeePage({
    required this.title,
    required this.child,
    this.footer,
    this.actions,
    super.key,
  });
  final String title;
  final Widget child;
  final Widget? footer;
  final List<Widget>? actions;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr(title)), actions: actions),
    body: SafeArea(
      top: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: child),
              if (footer != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                  child: footer!,
                ),
            ],
          ),
        ),
      ),
    ),
  );
}
