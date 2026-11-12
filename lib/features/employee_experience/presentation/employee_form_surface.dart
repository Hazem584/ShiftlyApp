import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/employee_design.dart';

/// Forms share validation and mutations with the manager UI, while employees
/// get the full-screen form hierarchy specified by the mobile design.
class EmployeeFormSurface extends StatelessWidget {
  const EmployeeFormSurface({
    required this.title,
    required this.content,
    required this.actions,
    this.scrollable = false,
    super.key,
  });
  final bool scrollable;
  final Widget title, content;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) {
    if (!EmployeeDesign.applies(context)) {
      return AlertDialog(
        title: title,
        content: content,
        actions: actions,
        scrollable: scrollable,
      );
    }
    return Scaffold(
      appBar: AppBar(title: title),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: content,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: actions
                        .where((action) => action is! TextButton)
                        .toList()
                        .reversed
                        .map(
                          (action) => Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: action,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
