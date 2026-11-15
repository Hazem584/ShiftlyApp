import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:shiftly/features/chat/domain/entities/chat_document_preview.dart';

import 'chat_preview_text.dart';

ChatDocumentPreview previewChatWorkbook(Uint8List bytes) {
  final directory = ZipDirectory.read(InputStream(bytes));
  final expanded = directory.fileHeaders.fold<int>(
    0,
    (sum, entry) => sum + (entry.uncompressedSize ?? 0),
  );
  if (directory.fileHeaders.length > 500 ||
      expanded > 8 * 1024 * 1024 ||
      directory.fileHeaders.any(
        (entry) => (entry.uncompressedSize ?? 0) > 4 * 1024 * 1024,
      )) {
    throw const FormatException('Workbook exceeds preview budget');
  }
  final workbook = Excel.decodeBytes(bytes);
  final sheets = <ChatDocumentSheet>[];
  var truncated = workbook.tables.length > 10;
  for (final entry in workbook.tables.entries.take(10)) {
    final sheet = entry.value;
    truncated = truncated || sheet.maxRows > 100 || sheet.maxColumns > 20;
    final rows = <List<String>>[];
    for (var r = 0; r < sheet.maxRows && r < 100; r++) {
      rows.add([
        for (var c = 0; c < sheet.maxColumns && c < 20; c++)
          previewCell(
            sheet
                    .cell(
                      CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r),
                    )
                    .value
                    ?.toString() ??
                '',
          ),
      ]);
    }
    sheets.add(ChatDocumentSheet(entry.key, rows));
  }
  return ChatDocumentPreview(sheets: sheets, truncated: truncated);
}
