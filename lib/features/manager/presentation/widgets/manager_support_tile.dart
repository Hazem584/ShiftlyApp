import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class ManagerSupportTile extends StatelessWidget {
  const ManagerSupportTile({super.key});
  @override
  Widget build(BuildContext context) => ListTile(
    leading: const Icon(Icons.help_outline),
    title: Text(context.tr('Support and service information')),
    onTap: () => showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('Support and service information'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 24),
              Text(
                context.tr(
                  'For workspace access or schedule questions, contact your workspace manager.',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr(
                  'For an unresolved operation, keep its saved request or support reference. Do not submit a duplicate operation.',
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('Close')),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
