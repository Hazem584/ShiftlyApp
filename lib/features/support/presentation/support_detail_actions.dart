import 'package:flutter/material.dart';
import 'package:shiftly/core/error/api_exception.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';

String supportLoadError(Object e) =>
    e is ApiException ? e.message : 'Could not load the support report.';

String supportReplyError(Object e) => e is ApiException
    ? e.message
    : 'Could not send the reply. Retry safely.';

Widget buildSupportDetailPlaceholder(
  BuildContext context, {
  required String? error,
  required VoidCallback onRetry,
}) => error == null
    ? const AppContentLoading()
    : Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.tr(error)),
            TextButton(onPressed: onRetry, child: Text(context.tr('Retry'))),
          ],
        ),
      );
