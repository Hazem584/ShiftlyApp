import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import '../design/access_action.dart';
import '../design/access_notice.dart';
import '../design/access_page.dart';

class AccessExpiredView extends StatelessWidget {
  const AccessExpiredView({required this.onSignIn, super.key});
  final VoidCallback onSignIn;
  @override
  Widget build(BuildContext context) => AccessPage(
    title: 'Session expired',
    footer: AccessAction(label: context.tr('Sign in'), onPressed: onSignIn),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          context.tr('Let’s sign you in again.'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 48),
        const AccessNotice('Your session has expired. Please sign in again.'),
      ],
    ),
  );
}
