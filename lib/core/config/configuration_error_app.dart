import 'package:flutter/material.dart';
import 'package:shiftly/core/theme/app_theme.dart';

class ConfigurationErrorApp extends StatelessWidget {
  const ConfigurationErrorApp({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme(),
    home: Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.settings_outlined, size: 52),
                const SizedBox(height: AppSpacing.m),
                Text(
                  'Shiftly is not configured',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppSpacing.s),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
