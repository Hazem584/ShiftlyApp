import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/support/presentation/support_tile.dart';

import 'communication_page.dart';

class ServiceInformationScreen extends StatelessWidget {
  const ServiceInformationScreen({super.key});
  @override
  Widget build(BuildContext context) => CommunicationPage(
    title: 'Service information',
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          child: ListTile(
            title: Text(context.tr('Need help with work?')),
            subtitle: Text(context.tr('Contact your workspace manager.')),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: ListTile(
            title: Text(context.tr('Attendance recovery')),
            subtitle: Text(context.tr('Include your saved request reference.')),
          ),
        ),
        const SizedBox(height: 14),
        const SupportTile(),
        const SizedBox(height: 14),
        Card(
          child: ListTile(
            key: const Key('app-information'),
            title: const Text('Shiftly'),
            subtitle: Text(context.tr('App information and licenses')),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Shiftly',
              children: [
                Text(
                  context.tr(
                    'Your team, shifts, attendance and tasks in one place.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
