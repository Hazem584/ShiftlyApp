import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/presentation/widgets/chat_document_content.dart';

class ChatDocumentPreviewScreen extends StatefulWidget {
  const ChatDocumentPreviewScreen({
    required this.bytes,
    required this.fileName,
    required this.sourceId,
    required this.hasAccess,
    required this.onDownload,
    this.accessChanges,
    super.key,
  });
  final Uint8List bytes;
  final String fileName, sourceId;
  final bool Function() hasAccess;
  final Future<bool> Function() onDownload;
  final Stream<int>? accessChanges;
  @override
  State<ChatDocumentPreviewScreen> createState() =>
      _ChatDocumentPreviewScreenState();
}

class _ChatDocumentPreviewScreenState extends State<ChatDocumentPreviewScreen> {
  bool _saving = false;
  Future<void> _download() async {
    if (_saving || !widget.hasAccess()) return;
    setState(() => _saving = true);
    try {
      final saved = await widget.onDownload();
      if (mounted && saved && widget.hasAccess()) _notice('File downloaded.');
    } catch (_) {
      if (mounted && widget.hasAccess()) {
        _notice('Could not download the document. Try again.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _notice(String text) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.tr(text))));
  @override
  Widget build(BuildContext context) => StreamBuilder<int>(
    stream: widget.accessChanges,
    builder: (context, _) {
      final allowed = widget.hasAccess();
      return Scaffold(
        appBar: AppBar(
          title: Text(
            allowed ? widget.fileName : context.tr('Document'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        body: allowed
            ? ChatDocumentContent(
                bytes: widget.bytes,
                fileName: widget.fileName,
                sourceId: widget.sourceId,
              )
            : Center(child: Text(context.tr('Chat access unavailable.'))),
        bottomNavigationBar: allowed
            ? SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: FilledButton.icon(
                    key: const Key('download-preview-document'),
                    onPressed: _saving ? null : _download,
                    icon: _saving
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_rounded),
                    label: Text(context.tr('Download file')),
                  ),
                ),
              )
            : null,
      );
    },
  );
}
