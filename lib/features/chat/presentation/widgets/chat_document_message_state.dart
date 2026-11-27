import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/features/chat/domain/entities/chat_cache_scope.dart';
import 'package:shiftly/features/chat/presentation/cubit/chat_groups_cubit.dart';

import '../controllers/chat_document_bytes.dart';
import '../controllers/chat_document_controller.dart';
import '../controllers/open_chat_document_preview.dart';
import 'chat_document_message.dart';
import 'chat_document_tile.dart';

class ChatDocumentMessageState extends State<ChatDocumentMessage> {
  bool _busy = false;
  late final _controller = widget.controller ?? ChatDocumentController();
  final _bytes = ChatDocumentBytes();
  bool _allowed(ChatGroupsCubit groups, FeatureSessionScope session) =>
      mounted &&
      groups.scope == session &&
      widget.workspaceId == session.workspaceId &&
      (groups.mediaCache == null ||
          groups.mediaCache!.storage.authorized(
            ChatCacheScope.fromSession(session, widget.message.groupId),
          ));

  @override
  void didUpdateWidget(covariant ChatDocumentMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message ||
        oldWidget.workspaceId != widget.workspaceId) {
      _bytes.clear();
    }
  }

  Future<void> _act({required bool preview}) async {
    if (_busy || widget.message.attachment == null) return;
    final groups = context.read<ChatGroupsCubit>();
    final session = groups.scope;
    if (session == null || !_allowed(groups, session)) return;
    setState(() => _busy = true);
    try {
      final bytes = await _bytes.load(
        session,
        () => _controller.load(
          message: widget.message,
          repository: widget.repository,
          session: session,
          cache: groups.mediaCache,
          hasAccess: () => _allowed(groups, session),
        ),
      );
      if (!mounted || !_allowed(groups, session)) return;
      final attachment = widget.message.attachment!;
      if (preview) {
        await openChatDocumentPreview(
          context,
          bytes: bytes,
          messageId: widget.message.id,
          attachment: attachment,
          session: session,
          accessChanges: groups.mediaCache?.storage.revisions,
          hasAccess: () => _allowed(groups, session),
          onDownload: () => _controller.download(bytes, attachment),
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
  Widget build(BuildContext context) => ChatDocumentTile(
    attachment: widget.message.attachment,
    busy: _busy,
    onPreview: () => _act(preview: true),
    onDownload: () => _act(preview: false),
  );
}
