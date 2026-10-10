import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/chat/presentation/cubit/pending_chat_message.dart';
import 'package:shiftly/features/chat/presentation/widgets/message_delivery_status.dart';

class PendingMessageFooter extends StatelessWidget {
  const PendingMessageFooter({
    super.key,
    required this.pending,
    required this.timezone,
    required this.onRetry,
    required this.onCancel,
  });

  final PendingChatMessage pending;
  final String timezone;
  final Future<void> Function(String) onRetry, onCancel;

  @override
  Widget build(BuildContext context) {
    final failed =
        pending.status == ChatUploadState.failed ||
        pending.status == ChatUploadState.uncertain;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (failed)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              context.tr(
                pending.status == ChatUploadState.uncertain
                    ? 'Confirmation unavailable — retry safely'
                    : pending.failure?.message ?? 'Message failed to send.',
              ),
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (pending.status == ChatUploadState.uploading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(
              value: pending.progress.clamp(0, 1),
              minHeight: 2,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 5,
          children: [
            if (failed)
              TextButton(
                onPressed: () => onRetry(pending.clientMessageId),
                child: Text(context.tr('Retry')),
              ),
            if (pending.createdAt != null)
              Text(
                WorkspaceTime.time(
                  pending.createdAt!,
                  timezone,
                  locale: Localizations.localeOf(context).toString(),
                ),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            MessageDeliveryStatus(
              pending: pending.status != ChatUploadState.sent,
              failed: failed,
            ),
            if (pending.canCancel)
              PopupMenuButton<String>(
                tooltip: context.tr('Cancel upload'),
                padding: EdgeInsets.zero,
                iconSize: 16,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 40),
                onSelected: (_) => onCancel(pending.clientMessageId),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'cancel',
                    child: Text(context.tr('Cancel')),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
