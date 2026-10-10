import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/app_form_dialog.dart';

abstract final class ShiftlyChatDialog {
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    bool destructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          useRootNavigator: false,
          barrierDismissible: false,
          builder: (dialogContext) => AppFormDialog(
            title: title,
            icon: destructive
                ? Icons.warning_amber_rounded
                : Icons.chat_outlined,
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(context.tr('Cancel')),
              ),
              FilledButton(
                style: destructive
                    ? FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                      )
                    : null,
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(confirmText),
              ),
            ],
          ),
        ) ??
        false;
  }

  static Future<T?> showBody<T>(BuildContext context, {required Widget body}) =>
      showDialog<T>(
        context: context,
        useRootNavigator: false,
        barrierDismissible: false,
        builder: (_) => body,
      );
}
