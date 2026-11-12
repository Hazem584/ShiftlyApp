import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import '../domain/support_repository.dart';

class SupportTile extends StatelessWidget {
  const SupportTile({super.key});
  @override
  Widget build(BuildContext context) {
    if (!getIt.isRegistered<SupportRepository>()) {
      return const SizedBox.shrink();
    }
    return Card(
      child: ListTile(
        key: const Key('support-reports'),
        leading: const Icon(Icons.support_agent_outlined),
        title: Text(context.tr('Help and problem reports')),
        subtitle: Text(
          context.tr('Report a problem and follow replies from support'),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/support'),
      ),
    );
  }
}
