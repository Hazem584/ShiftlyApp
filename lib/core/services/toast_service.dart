import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/app_toast_widget.dart';

abstract final class ToastService {
  static const defaultDuration = Duration(seconds: 3);

  static void success(
    BuildContext context, {
    required String message,
    Duration duration = defaultDuration,
    ToastGravity gravity = ToastGravity.TOP,
  }) => show(
    context,
    message: message,
    type: ToastType.success,
    duration: duration,
    gravity: gravity,
  );

  static void error(
    BuildContext context, {
    required String message,
    Duration duration = defaultDuration,
    ToastGravity gravity = ToastGravity.TOP,
  }) => show(
    context,
    message: message,
    type: ToastType.error,
    duration: duration,
    gravity: gravity,
  );

  static void warning(
    BuildContext context, {
    required String message,
    Duration duration = defaultDuration,
    ToastGravity gravity = ToastGravity.TOP,
  }) => show(
    context,
    message: message,
    type: ToastType.warning,
    duration: duration,
    gravity: gravity,
  );

  static void info(
    BuildContext context, {
    required String message,
    Duration duration = defaultDuration,
    ToastGravity gravity = ToastGravity.TOP,
  }) => show(
    context,
    message: message,
    type: ToastType.info,
    duration: duration,
    gravity: gravity,
  );

  static void show(
    BuildContext context, {
    required String message,
    required ToastType type,
    Duration duration = defaultDuration,
    ToastGravity gravity = ToastGravity.TOP,
  }) {
    if (!context.mounted) return;
    final toast = FToast()..init(context);
    toast.removeQueuedCustomToasts();
    toast.showToast(
      child: AppToastWidget(
        message: context.tr(message),
        type: type,
        onClose: toast.removeCustomToast,
      ),
      gravity: gravity,
      toastDuration: duration,
      fadeDuration: const Duration(milliseconds: 220),
      isDismissible: true,
    );
  }

  static void dismissAll() => FToast().removeQueuedCustomToasts();
}
