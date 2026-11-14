import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import 'communication_appearance.dart';

Future<bool> confirmCommunicationAction(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  String? actionKey,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(c.tr(title)),
        content: Text(c.tr(message)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text(c.tr('Cancel')),
          ),
          FilledButton(
            key: actionKey == null ? null : Key(actionKey),
            onPressed: () => Navigator.pop(c, true),
            child: Text(c.tr(action)),
          ),
        ],
      ),
    ) ??
    false;
Future<T?> openCommunicationPage<T>(BuildContext context, Widget page) =>
    Navigator.of(context, rootNavigator: true).push<T>(
      MaterialPageRoute<T>(
        builder: (_) => CommunicationAppearance(child: page),
      ),
    );
