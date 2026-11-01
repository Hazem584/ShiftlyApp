import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import '../design/access_action.dart';
import '../design/access_notice.dart';
import '../design/access_page.dart';

class WorkspaceUnavailableView extends StatelessWidget {
  const WorkspaceUnavailableView({
    required this.onChoose,
    required this.onSignOut,
    super.key,
  });
  final VoidCallback onChoose, onSignOut;
  @override
  Widget build(BuildContext context) => AccessPage(
    title: 'Workspace unavailable',
    footer: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AccessAction(
          label: context.tr('Choose another workspace'),
          onPressed: onChoose,
        ),
        TextButton(onPressed: onSignOut, child: Text(context.tr('Sign out'))),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr('This workspace is unavailable.'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 48),
        const AccessNotice(
          'Your membership may be suspended or the workspace may no longer be available. Contact your manager for help.',
        ),
      ],
    ),
  );
}
