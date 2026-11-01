import 'package:flutter/material.dart';

class AccessField extends StatelessWidget {
  const AccessField({required this.label, required this.child, super.key});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(fontWeight: FontWeight.w500),
      ),
      const SizedBox(height: 8),
      child,
    ],
  );
}
