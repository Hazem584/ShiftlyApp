import 'dart:typed_data';

import 'package:shiftly/features/chat/domain/entities/chat_document_preview.dart';

import 'chat_csv_preview.dart';
import 'chat_preview_text.dart';
import 'chat_workbook_preview.dart';

typedef ChatDocumentPreviewInput = ({Uint8List bytes, String extension});

/// Bounded output for preview; download always retains the original file.
ChatDocumentPreview parseChatDocumentPreview(ChatDocumentPreviewInput input) {
  if (input.extension == 'xlsx') return previewChatWorkbook(input.bytes);
  if (input.extension != 'txt' && input.extension != 'csv') {
    throw const FormatException('Preview unavailable for this file format');
  }
  const limit = 128 * 1024;
  final raw = input.bytes.length > limit
      ? Uint8List.sublistView(input.bytes, 0, limit)
      : input.bytes;
  final text = decodePreviewText(raw);
  if (input.extension == 'txt') {
    return ChatDocumentPreview(
      text: text,
      truncated: input.bytes.length > limit,
    );
  }
  final rows = previewCsvRows(text);
  return ChatDocumentPreview(
    sheets: [
      ChatDocumentSheet(
        'CSV',
        rows.take(100).map((r) => r.take(20).toList()).toList(),
      ),
    ],
    truncated:
        input.bytes.length > limit ||
        rows.length > 100 ||
        rows.any((r) => r.length > 20),
  );
}
