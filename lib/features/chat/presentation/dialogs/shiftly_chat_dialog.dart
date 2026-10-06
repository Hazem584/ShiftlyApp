import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';

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
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
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

  static Future<T?> showBody<T>(
    BuildContext context, {
    required Widget body,
    DialogType type = DialogType.noHeader,
  }) async =>
      (await AwesomeDialog(
            context: context,
            useRootNavigator: false,
            keyboardAware: true,
            dismissOnTouchOutside: false,
            dismissOnBackKeyPress: false,
            dialogType: type,
            animType: AnimType.scale,
            body: body,
            dialogBackgroundColor: Theme.of(context).colorScheme.surface,
            width: 520,
          ).show())
          as T?;
}
