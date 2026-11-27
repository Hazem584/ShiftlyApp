import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/domain/entities/chat_attachment.dart';

class ChatDocumentTile extends StatelessWidget {
  const ChatDocumentTile({
    required this.attachment,
    required this.busy,
    required this.onPreview,
    required this.onDownload,
    super.key,
  });

  final ChatAttachment? attachment;
  final bool busy;
  final VoidCallback onPreview, onDownload;

  @override
  Widget build(BuildContext context) {
    final attachment = this.attachment;
    final foreground =
        DefaultTextStyle.of(context).style.color ??
        Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: busy || attachment == null ? null : onPreview,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Icon(
                    attachment?.mimeType == 'application/pdf'
                        ? Icons.picture_as_pdf_outlined
                        : Icons.description_outlined,
                    size: 36,
                    color: foreground,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      attachment?.fileName ?? context.tr('Document'),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (attachment != null)
            Text(
              '${(attachment.sizeBytes / 1000000).toStringAsFixed(2)} MB',
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: foreground),
            ),
          const SizedBox(height: 8),
          if (busy)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              OutlinedButton.icon(
                key: const Key('preview-chat-document'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: foreground,
                  side: BorderSide(color: foreground.withValues(alpha: .4)),
                ),
                onPressed: busy || attachment == null ? null : onPreview,
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: Text(context.tr('Preview file')),
              ),
              TextButton.icon(
                key: const Key('download-chat-document'),
                style: TextButton.styleFrom(foregroundColor: foreground),
                onPressed: busy || attachment == null ? null : onDownload,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(context.tr('Download file')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
