import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatDocumentMessage extends StatefulWidget {
  const ChatDocumentMessage({
    required this.message,
    required this.repository,
    required this.workspaceId,
    super.key,
  });
  final ChatMessage message;
  final ChatRepository repository;
  final String workspaceId;
  @override
  State<ChatDocumentMessage> createState() => _ChatDocumentMessageState();
}

class _ChatDocumentMessageState extends State<ChatDocumentMessage> {
  bool _busy = false;
  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    final groups = context.read<ChatGroupsCubit>();
    final scope = groups.scope, cache = groups.mediaCache;
    try {
      if (scope == null) return;
      final key = ChatCacheScope.fromSession(scope, widget.message.groupId);
      if (cache == null) {
        final media = await widget.repository.mediaUrl(
          widget.workspaceId,
          widget.message.groupId,
          widget.message.id,
        );
        if (!mounted || groups.scope != scope) return;
        await launchUrl(media.url, mode: LaunchMode.externalApplication);
        return;
      }
      final file = await cache.resolve(key, widget.message, widget.repository);
      cache.pin(file);
      try {
        final bytes = await file.readAsBytes();
        if (!mounted || groups.scope != scope || !cache.storage.authorized(key)) {
          return;
        }
        final name = widget.message.attachment?.fileName ?? 'document.pdf';
        final mime = widget.message.attachment?.mimeType ?? 'application/pdf';
        if (kIsWeb) {
          await XFile.fromData(bytes, mimeType: mime, name: name).saveTo(name);
        } else {
          final box = context.findRenderObject() as RenderBox?;
          await SharePlus.instance.share(
            ShareParams(
              files: [XFile.fromData(bytes, mimeType: mime, name: name)],
              fileNameOverrides: [name],
              sharePositionOrigin: box == null
                  ? null
                  : box.localToGlobal(Offset.zero) & box.size,
            ),
          );
        }
      } finally {
        cache.unpin(file);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr('Could not download the document. Try again.'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final attachment = widget.message.attachment;
    return SizedBox(
      width: 250,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                attachment?.mimeType == 'application/pdf'
                    ? Icons.picture_as_pdf_outlined
                    : Icons.description_outlined,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  attachment?.fileName ?? context.tr('Document'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (attachment != null)
            Text(
              '${(attachment.sizeBytes / 1000000).toStringAsFixed(2)} MB',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          TextButton.icon(
            onPressed: _busy || attachment == null ? null : _save,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
            label: Text(context.tr('Save or share document')),
          ),
        ],
      ),
    );
  }
}
