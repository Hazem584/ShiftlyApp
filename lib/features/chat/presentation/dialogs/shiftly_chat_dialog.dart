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
    var confirmed = false;
    await AwesomeDialog(
      context: context,
      useRootNavigator: false,
      keyboardAware: true,
      dismissOnTouchOutside: false,
      dismissOnBackKeyPress: true,
      dialogType: destructive ? DialogType.warning : DialogType.question,
      animType: AnimType.scale,
      title: title,
      desc: message,
      btnCancelText: 'Cancel',
      btnCancelOnPress: () {},
      btnOkText: confirmText,
      btnOkColor: destructive
          ? Theme.of(context).colorScheme.error
          : Theme.of(context).colorScheme.primary,
      btnOkOnPress: () => confirmed = true,
      buttonsBorderRadius: BorderRadius.circular(14),
      dialogBackgroundColor: Theme.of(context).colorScheme.surface,
    ).show();
    return confirmed;
  }

  static Future<T?> showBody<T>(
    BuildContext context, {
    required Widget body,
    DialogType type = DialogType.noHeader,
  }) async => (await AwesomeDialog(
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
  ).show()) as T?;
}
