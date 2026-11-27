import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

pw.TextDirection pdfTextDirection(String value) =>
    RegExp(r'[\u0600-\u06ff]').hasMatch(value)
    ? pw.TextDirection.rtl
    : pw.TextDirection.ltr;

pw.Widget buildPdfMetaRow(List<Object> row, bool rtl) => row.length == 1
    ? pw.Text(row.single.toString(), style: const pw.TextStyle(fontSize: 9))
    : pw.Row(
        children: [
          pw.Text('${row.first}  ', style: const pw.TextStyle(fontSize: 9)),
          pw.Expanded(
            child: pw.Text(
              row[1].toString(),
              textDirection: pdfTextDirection(row[1].toString()),
              textAlign: rtl ? pw.TextAlign.right : pw.TextAlign.left,
              style: const pw.TextStyle(fontSize: 9),
            ),
          ),
        ],
      );

pw.Widget buildPdfReportTable(
  List<String> headers,
  List<List<Object>> values,
  pw.Font font,
  bool rtl,
) {
  final dir = rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;
  final rows = values
      .map(
        (r) => r
            .map((v) => v is double ? v.toStringAsFixed(2) : v.toString())
            .toList(),
      )
      .map((r) => rtl ? r.reversed.toList() : r)
      .toList();
  return pw.TableHelper.fromTextArray(
    headers: rtl ? headers.reversed.toList() : headers,
    data: rows,
    headerStyle: pw.TextStyle(font: font, fontSize: 8),
    headerDirection: dir,
    tableDirection: dir,
    cellBuilder: (_, v, _) => pw.Text(
      v.toString(),
      textDirection: pdfTextDirection(v.toString()),
      style: pw.TextStyle(font: font, fontSize: 7),
    ),
    cellStyle: pw.TextStyle(font: font, fontSize: 7),
    headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
    cellPadding: const pw.EdgeInsets.all(4),
    cellAlignment: rtl ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
  );
}
