import 'chat_preview_text.dart';

List<List<String>> previewCsvRows(String text) {
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
    row.add(previewCell(cell.toString()));
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
