import 'package:flutter/material.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/core/widgets/screen_header.dart';
import 'package:shiftly/core/theme/app_theme.dart';

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
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
        child: Column(
          children: [
            ScreenHeader(title: title, subtitle: 'Shift Lab manager workspace'),
            const SizedBox(height: AppSpacing.xl),
            Expanded(
              child: EmptyState(
                icon: icon,
                title: '$title is coming next',
                message: message,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
