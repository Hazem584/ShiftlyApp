import 'package:flutter/material.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

class AccessNotice extends StatelessWidget {
  const AccessNotice(
    this.message, {
    this.failure,
    this.error = false,
    super.key,
  });
  final String message;
  final Failure? failure;
  final bool error;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isError = error || failure != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isError ? colors.errorContainer : colors.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(failure?.message ?? message),
            style: TextStyle(
              color: isError
                  ? colors.onErrorContainer
                  : colors.onPrimaryContainer,
              fontSize: 15,
              height: 1.35,
            ),
          ),
          if (failure?.requestId != null) ...[
            const SizedBox(height: 8),
            SelectableText(
              context.tr('Request ID: {id}', {'id': failure!.requestId!}),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
