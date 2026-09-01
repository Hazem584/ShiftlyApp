import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shiftly/core/routing/app_navigator.dart';

class AppToast {
  const AppToast._();

  static void show(String message) {
    final context = AppNavigator.key.currentContext;
    if (_useSnackBarFallback) {
      _showSnackBar(context, message);
      return;
    }

    try {
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.black,
        textColor: Colors.white,
      );
    } catch (_) {
      _showSnackBar(context, message);
    }
  }

  static bool get _useSnackBarFallback {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
  }

  static void _showSnackBar(BuildContext? context, String message) {
    if (context == null) {
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }

    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black87,
        ),
      );
  }
}
