import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

Future<bool?> showDeleteNotificationDialog(BuildContext context) =>
    showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Delete notification?')),
        content: Text(
          context.tr('This notification will be permanently removed.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('Cancel')),
          ),
          FilledButton(
            key: const Key('confirm-delete-notification'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('Delete')),
          ),
        ],
      ),
    );
