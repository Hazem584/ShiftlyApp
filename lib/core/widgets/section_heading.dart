import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class SectionHeading extends StatelessWidget {
  const SectionHeading({required this.title, this.trailing, super.key});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          context.tr(title),
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      ?trailing,
    ],
  );
}
