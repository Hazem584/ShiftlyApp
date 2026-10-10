import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class PointsEmpty extends StatelessWidget {
  const PointsEmpty({required this.icon, required this.text, super.key});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        Icon(icon),
        const SizedBox(height: 8),
        Text(context.tr(text), textAlign: TextAlign.center),
      ],
    ),
  );
}
