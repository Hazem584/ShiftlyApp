import 'package:flutter/material.dart';
import 'package:shiftly/core/widgets/empty_state.dart';

class FeaturePlaceholder extends StatelessWidget {
  const FeaturePlaceholder({
    required this.title,
    required this.icon,
    required this.message,
    super.key,
  });
  final String title;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: EmptyState(
      icon: icon,
      title: '$title is coming next',
      message: message,
    ),
  );
}
