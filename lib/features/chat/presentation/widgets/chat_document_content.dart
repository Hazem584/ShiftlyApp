import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/features/chat/domain/entities/chat_document_preview.dart';
import 'package:shiftly/features/chat/domain/services/chat_document_preview_parser.dart';

import 'chat_pdf_preview.dart';
import 'chat_spreadsheet_preview.dart';

class ChatDocumentContent extends StatefulWidget {
  const ChatDocumentContent({
    required this.bytes,
    required this.fileName,
    required this.sourceId,
    super.key,
  });
  final Uint8List bytes;
  final String fileName, sourceId;
  @override
  State<ChatDocumentContent> createState() => _ChatDocumentContentState();
}

class _ChatDocumentContentState extends State<ChatDocumentContent> {
  Future<ChatDocumentPreview>? _preview;
  String get extension => widget.fileName.split('.').last.toLowerCase();
  @override
  void initState() {
    super.initState();
    if (extension != 'pdf') {
      _preview = compute(parseChatDocumentPreview, (
        bytes: widget.bytes,
        extension: extension,
      ), debugLabel: 'shiftly.document.preview');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (extension == 'pdf') {
      return ChatPdfPreview(bytes: widget.bytes);
    }
    return FutureBuilder<ChatDocumentPreview>(
      future: _preview,
      builder: (context, snapshot) {
        if (snapshot.hasError) return _unavailable(context);
        final preview = snapshot.data;
        if (preview == null) return const AppContentLoading();
        if (preview.text case final text?) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (preview.truncated)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      context.tr(
                        'Preview is limited. Download to view the complete file.',
                      ),
                    ),
                  ),
                SelectableText(
                  text.isEmpty ? context.tr('This file is empty.') : text,
                ),
              ],
            ),
          );
        }
        return ChatSpreadsheetPreview(preview: preview);
      },
    );
  }

  Widget _unavailable(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Text(
        context.tr(
          'Preview unavailable. Download this file to open it in another app.',
        ),
        textAlign: TextAlign.center,
      ),
    ),
  );
}
