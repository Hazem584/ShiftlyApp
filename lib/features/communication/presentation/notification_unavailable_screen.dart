import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import 'communication_page.dart';

class NotificationUnavailableScreen extends StatelessWidget {
  const NotificationUnavailableScreen({super.key});
  @override
  Widget build(BuildContext context) => CommunicationPage(
    title: 'Item unavailable',
    footer: FilledButton(
      onPressed: () => Navigator.pop(context),
      child: Text(context.tr('Back to notifications')),
    ),
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 48),
        Text(
          context.tr('This item is unavailable.'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Text(
          context.tr(
            'It may have been deleted or your access may have changed. You can return to your notifications.',
          ),
        ),
        const SizedBox(height: 16),
        Text(
          context.tr('This notification destination is no longer available.'),
        ),
      ],
    ),
  );
}
