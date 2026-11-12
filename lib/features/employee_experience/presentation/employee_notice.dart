import 'package:flutter/material.dart';

class EmployeeNotice extends StatelessWidget {
  const EmployeeNotice({required this.child, super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(16),
    ),
    child: DefaultTextStyle.merge(
      style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer),
      child: child,
    ),
  );
}
