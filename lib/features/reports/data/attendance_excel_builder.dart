import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:shiftly/features/reports/data/attendance_export_data.dart';
import 'package:shiftly/features/reports/domain/report_export.dart';

ReportExportFile buildExcelReport(ExportSheetData data) {
  final strings = data.strings;
  final workbook = Excel.createExcel();
  workbook.rename('Sheet1', 'Summary');
  final summarySheet = workbook['Summary'];
  for (final row in data.metadata) {
    _append(summarySheet, row);
  }
  _append(summarySheet, []);
  _append(
    summarySheet,
    ExportSheetData.summaryHeaders.map(strings.text).toList(),
    header: true,
  );
  for (final row in data.summaryRows) {
    _append(summarySheet, row);
  }
  _append(summarySheet, ExportSheetData.summaryRow(data.totals), header: true);
  summarySheet.setColumnWidth(0, 28);
  for (var col = 1; col < ExportSheetData.summaryHeaders.length; col++) {
    summarySheet.setColumnWidth(col, 22);
  }
  final detailSheet = workbook['Details'];
  _append(
    detailSheet,
    ExportSheetData.detailHeaders.map(strings.text).toList(),
    header: true,
  );
  for (var col = 0; col < ExportSheetData.detailHeaders.length; col++) {
    detailSheet.setColumnWidth(col, col == 1 ? 40 : 28);
  }
  for (final row in data.details) {
    _append(detailSheet, row);
  }
  final bytes = workbook.encode();
  if (bytes == null) {
    throw const FormatException('Unable to create workbook');
  }
  return ReportExportFile(
    Uint8List.fromList(bytes),
    '${data.basename}.xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );
}

void _append(Sheet sheet, List<Object> values, {bool header = false}) {
  final row = sheet.maxRows;
  sheet.appendRow(
    values.map<CellValue>((value) {
      if (value is int) return IntCellValue(value);
      if (value is double) return DoubleCellValue(value);
      return TextCellValue(value.toString());
    }).toList(),
  );
  for (var column = 0; column < values.length; column++) {
    sheet
        .cell(CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row))
        .cellStyle = CellStyle(
      bold: header,
      textWrapping: TextWrapping.WrapText,
      numberFormat: values[column] is double
          ? NumFormat.standard_2
          : NumFormat.standard_0,
    );
  }
}
