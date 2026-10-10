import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/theme/app_theme.dart';

class EaseHint extends StatelessWidget {
  const EaseHint({
    required this.message,
    this.icon = Icons.lightbulb_outline_rounded,
    super.key,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppPalette.of(context).orangeSoft,
      borderRadius: BorderRadius.circular(AppRadii.m),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppPalette.of(context).orange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              context.tr(message),
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppPalette.of(context).ink,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
