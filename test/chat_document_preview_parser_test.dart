import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/features/chat/domain/services/chat_document_preview_parser.dart';

void main() {
  test('CSV preserves quotes, embedded line breaks and empty cells', () {
    final preview = parseChatDocumentPreview((
      extension: 'csv',
      bytes: Uint8List.fromList(
        utf8.encode(
          'name,note,empty\r\n"Hazem","first\nsecond",\r\n"A""B",value,',
        ),
      ),
    ));
    expect(preview.sheets.single.rows, [
      ['name', 'note', 'empty'],
      ['Hazem', 'first\nsecond', ''],
      ['A"B', 'value', ''],
    ]);
  });
  test('semicolon CSV ignores quoted commas when detecting delimiter', () {
    final preview = parseChatDocumentPreview((
      extension: 'csv',
      bytes: Uint8List.fromList(
        utf8.encode('"one,two,three";value\nhello;world'),
      ),
    ));
    expect(preview.sheets.single.rows.first, ['one,two,three', 'value']);
  });
  test('text supports UTF-16 BOM and preserves Arabic', () {
    const text = 'ملف شيفتلي';
    final bytes = Uint8List.fromList([
      255,
      254,
      for (final c in text.codeUnits) ...[c & 255, c >> 8],
    ]);
    expect(
      parseChatDocumentPreview((bytes: bytes, extension: 'txt')).text,
      text,
    );
  });
  test('text preview has a size limit without modifying original bytes', () {
    final bytes = Uint8List.fromList(List.filled(150000, 65));
    final preview = parseChatDocumentPreview((bytes: bytes, extension: 'txt'));
    expect(preview.truncated, isTrue);
    expect(preview.text!.length, 128 * 1024);
    expect(bytes.length, 150000);
  });
  test('XLSX returns sheet names and bounded rows and columns', () {
    final workbook = Excel.createExcel();
    final sheet = workbook['Schedule'];
    for (var r = 0; r < 105; r++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r))
          .value = TextCellValue(
        'Row $r',
      );
    }
    final preview = parseChatDocumentPreview((
      bytes: Uint8List.fromList(workbook.encode()!),
      extension: 'xlsx',
    ));
    final rows = preview.sheets.firstWhere((s) => s.name == 'Schedule').rows;
    expect(rows, hasLength(100));
    expect(rows.first.single, 'Row 0');
    expect(preview.truncated, isTrue);
  });
  test('oversized expanded workbook is rejected before Excel parsing', () {
    final archive = Archive()
      ..addFile(
        ArchiveFile(
          'xl/worksheets/sheet1.xml',
          5 * 1024 * 1024,
          Uint8List(5 * 1024 * 1024),
        ),
      );
    final bytes = Uint8List.fromList(ZipEncoder().encode(archive)!);
    expect(
      () => parseChatDocumentPreview((bytes: bytes, extension: 'xlsx')),
      throwsFormatException,
    );
  });
  test('legacy XLS and corrupt XLSX report unavailable previews', () {
    final bytes = Uint8List.fromList([1, 2, 3]);
    expect(
      () => parseChatDocumentPreview((bytes: bytes, extension: 'xls')),
      throwsFormatException,
    );
    expect(
      () => parseChatDocumentPreview((bytes: bytes, extension: 'xlsx')),
      throwsA(anything),
    );
  });
}
