import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:shiftly/features/chat/domain/entities/chat_document_preview.dart';

typedef ChatDocumentPreviewInput = ({Uint8List bytes, String extension});

/// Bounded output for preview; download always retains the original file.
ChatDocumentPreview parseChatDocumentPreview(ChatDocumentPreviewInput input) {
  if (input.extension == 'xlsx') {
    final directory = ZipDirectory.read(InputStream(input.bytes));
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
    final workbook = Excel.decodeBytes(input.bytes);
    final sheets = <ChatDocumentSheet>[];
    var truncated = workbook.tables.length > 10;
    for (final entry in workbook.tables.entries.take(10)) {
      final sheet = entry.value;
      truncated = truncated || sheet.maxRows > 100 || sheet.maxColumns > 20;
      final rows = <List<String>>[];
      for (var r = 0; r < sheet.maxRows && r < 100; r++) {
        rows.add([
          for (var c = 0; c < sheet.maxColumns && c < 20; c++)
            _cell(
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
  if (input.extension != 'txt' && input.extension != 'csv') {
    throw const FormatException('Preview unavailable for this file format');
  }
  const limit = 128 * 1024;
  final raw = input.bytes.length > limit
      ? Uint8List.sublistView(input.bytes, 0, limit)
      : input.bytes;
  final text = _decode(raw);
  if (input.extension == 'txt') {
    return ChatDocumentPreview(
      text: text,
      truncated: input.bytes.length > limit,
    );
  }
  final rows = _csv(text);
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

String _cell(String value) =>
    value.length > 1000 ? value.substring(0, 1000) : value;
String _decode(Uint8List bytes) {
  if (bytes.length >= 2 &&
      ((bytes[0] == 255 && bytes[1] == 254) ||
          (bytes[0] == 254 && bytes[1] == 255))) {
    final little = bytes[0] == 255;
    return String.fromCharCodes([
      for (var i = 2; i + 1 < bytes.length; i += 2)
        little
            ? bytes[i] | (bytes[i + 1] << 8)
            : (bytes[i] << 8) | bytes[i + 1],
    ]);
  }
  return utf8
      .decode(bytes, allowMalformed: true)
      .replaceFirst(RegExp(r'^\uFEFF'), '');
}

List<List<String>> _csv(String text) {
  final first = text.split(RegExp(r'[\r\n]')).first;
  final counts = {',': 0, ';': 0, '\t': 0};
  var inQuotes = false;
  for (var i = 0; i < first.length; i++) {
    if (first[i] == '"') {
      if (inQuotes && i + 1 < first.length && first[i + 1] == '"') {
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (!inQuotes && counts.containsKey(first[i])) {
      counts[first[i]] = counts[first[i]]! + 1;
    }
  }
  final delimiters = counts.keys.toList()
    ..sort((a, b) => counts[b]!.compareTo(counts[a]!));
  final delimiter = delimiters.first;
  final rows = <List<String>>[];
  var row = <String>[], cell = StringBuffer(), quoted = false;
  void finishCell() {
    row.add(_cell(cell.toString()));
    cell = StringBuffer();
  }

  for (var i = 0; i < text.length && rows.length <= 100; i++) {
    final ch = text[i];
    if (ch == '"') {
      if (quoted && i + 1 < text.length && text[i + 1] == '"') {
        cell.write('"');
        i++;
      } else {
        quoted = !quoted;
      }
    } else if (!quoted && ch == delimiter) {
      finishCell();
    } else if (!quoted && (ch == '\n' || ch == '\r')) {
      finishCell();
      rows.add(row);
      row = [];
      if (ch == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
    } else {
      cell.write(ch);
    }
  }
  if (rows.length <= 100 && (row.isNotEmpty || cell.isNotEmpty)) {
    finishCell();
    rows.add(row);
  }
  return rows;
}
