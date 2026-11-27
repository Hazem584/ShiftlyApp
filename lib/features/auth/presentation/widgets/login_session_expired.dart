import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/access_screen.dart';

Widget buildExpiredSessionAccessScreen(
  BuildContext context, {
  required String message,
  required VoidCallback onAcknowledge,
}) => AccessScreen(
  title: 'Session expired',
  actions: [
    FilledButton(onPressed: onAcknowledge, child: Text(context.tr('Sign in'))),
  ],
  children: [
    Text(
      context.tr('Let’s sign you in again.'),
      style: Theme.of(context).textTheme.headlineMedium,
    ),
    const SizedBox(height: 18),
    Text(context.tr(message), key: const Key('login-session-message')),
  ],
);
