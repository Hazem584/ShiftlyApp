import 'package:flutter/material.dart';
import 'package:shiftly/core/error/failure.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

/// Keeps a failure and its recovery action visible beside the affected content.
class FailureNotice extends StatelessWidget {
  const FailureNotice({
    required this.failure,
    this.onRefresh,
    this.refreshing = false,
    super.key,
  });

  final Failure failure;
  final VoidCallback? onRefresh;
  final bool refreshing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title = switch (failure.kind) {
      FailureKind.network => 'Connection unavailable',
      FailureKind.timeout => 'The request took too long',
      FailureKind.authentication => 'Sign in to continue',
      FailureKind.authorization => 'Access needs attention',
      FailureKind.validation => 'Review this action',
      FailureKind.server => 'Service temporarily unavailable',
      FailureKind.cancelled => 'Request cancelled',
      FailureKind.unknown => 'Unable to confirm the latest status',
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('failure-notice'),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(title),
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: colors.onErrorContainer),
            ),
            const SizedBox(height: 6),
            Text(
              context.tr(failure.message),
              style: TextStyle(color: colors.onErrorContainer),
            ),
            if (failure.requestId != null) ...[
              const SizedBox(height: 8),
              SelectableText(
                context.tr('Support reference: {id}', {
                  'id': failure.requestId!,
                }),
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.onErrorContainer),
              ),
            ],
            if (onRefresh != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: refreshing ? null : onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  context.tr(
                    refreshing ? 'Refreshing status…' : 'Refresh status',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
