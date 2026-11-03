import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_models.dart';
import 'package:shiftly/features/chat/domain/repositories/chat_repository.dart';
import 'package:shiftly/features/chat/presentation/controllers/chat_document_controller.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';
import 'package:shiftly/features/chat/presentation/screens/chat_document_preview_screen.dart';

class ChatDocumentMessage extends StatefulWidget {
  const ChatDocumentMessage({
    required this.message,
    required this.repository,
    required this.workspaceId,
    this.controller,
    super.key,
  });
  final ChatMessage message;
  final ChatRepository repository;
  final String workspaceId;
  final ChatDocumentController? controller;
  @override
  State<ChatDocumentMessage> createState() => _ChatDocumentMessageState();
}

class _ChatDocumentMessageState extends State<ChatDocumentMessage> {
  bool _busy = false;
  late final _controller = widget.controller ?? ChatDocumentController();
  Future<Uint8List>? _bytes;
  FeatureSessionScope? _session;
  bool _allowed(ChatGroupsCubit groups, FeatureSessionScope session) =>
      mounted &&
      groups.scope == session &&
      widget.workspaceId == session.workspaceId &&
      (groups.mediaCache == null ||
          groups.mediaCache!.storage.authorized(
            ChatCacheScope.fromSession(session, widget.message.groupId),
          ));

  Future<Uint8List> _load(ChatGroupsCubit groups, FeatureSessionScope session) {
    if (_session != session) {
      _bytes = null;
      _session = session;
    }
    return _bytes ??= _controller
        .load(
          message: widget.message,
          repository: widget.repository,
          session: session,
          cache: groups.mediaCache,
          hasAccess: () => _allowed(groups, session),
        )
        .catchError((Object error) {
          _bytes = null;
          throw error;
        });
  }

  @override
  void didUpdateWidget(covariant ChatDocumentMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message ||
        oldWidget.workspaceId != widget.workspaceId) {
      _bytes = null;
    }
  }

  Future<void> _act({required bool preview}) async {
    if (_busy || widget.message.attachment == null) return;
    final groups = context.read<ChatGroupsCubit>(),
        session = context.read<ChatGroupsCubit>().scope;
    if (session == null || !_allowed(groups, session)) return;
    setState(() => _busy = true);
    try {
      final bytes = await _load(groups, session);
      if (!mounted || !_allowed(groups, session)) return;
      final attachment = widget.message.attachment!;
      if (preview) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ChatDocumentPreviewScreen(
              bytes: bytes,
              fileName: attachment.fileName ?? context.tr('Document'),
              sourceId:
                  '${session.userId}:${widget.message.id}:${attachment.id}',
              accessChanges: groups.mediaCache?.storage.revisions,
              hasAccess: () => _allowed(groups, session),
              onDownload: () async {
                if (!_allowed(groups, session)) {
                  throw StateError('Chat access unavailable');
                }
                return _controller.download(bytes, attachment);
              },
            ),
          ),
        );
      } else {
        final saved = await _controller.download(bytes, attachment);
        if (_allowed(groups, session) && saved) _notice('File downloaded.');
      }
    } catch (_) {
      if (_allowed(groups, session)) {
        _notice(
          preview
              ? 'Could not preview the document. Try again.'
              : 'Could not download the document. Try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _notice(String text) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr(text))));
  @override
  Widget build(BuildContext context) {
    final attachment = widget.message.attachment;
    final foreground =
        DefaultTextStyle.of(context).style.color ??
        Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _busy || attachment == null
                ? null
                : () => _act(preview: true),
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
          if (_busy)
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
                onPressed: _busy || attachment == null
                    ? null
                    : () => _act(preview: true),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: Text(context.tr('Preview file')),
              ),
              TextButton.icon(
                key: const Key('download-chat-document'),
                style: TextButton.styleFrom(foregroundColor: foreground),
                onPressed: _busy || attachment == null
                    ? null
                    : () => _act(preview: false),
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
