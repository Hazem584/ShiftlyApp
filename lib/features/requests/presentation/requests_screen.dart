import 'package:flutter/material.dart';
import 'package:shiftly/core/widgets/feature_placeholder.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FeaturePlaceholder(
      title: 'Requests',
      icon: Icons.inbox_outlined,
      message:
          'Check-in, leave, and early-departure requests will be managed here.',
    );
  }
}
