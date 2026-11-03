import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/chat/domain/entities/chat_document_preview.dart';

class ChatSpreadsheetPreview extends StatefulWidget {
  const ChatSpreadsheetPreview({required this.preview, super.key});
  final ChatDocumentPreview preview;
  @override
  State<ChatSpreadsheetPreview> createState() => _ChatSpreadsheetPreviewState();
}

class _ChatSpreadsheetPreviewState extends State<ChatSpreadsheetPreview> {
  int _sheet = 0;
  @override
  Widget build(BuildContext context) {
    final sheets = widget.preview.sheets;
    if (sheets.isEmpty) {
      return Center(child: Text(context.tr('This file is empty.')));
    }
    final sheet = sheets[_sheet];
    final columns = sheet.rows.fold<int>(
      0,
      (n, row) => row.length > n ? row.length : n,
    );
    return Column(
      children: [
        if (sheets.length > 1)
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButton<int>(
              isExpanded: true,
              value: _sheet,
              items: [
                for (var i = 0; i < sheets.length; i++)
                  DropdownMenuItem(
                    value: i,
                    child: Text(
                      sheets[i].name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _sheet = value);
              },
            ),
          ),
        if (widget.preview.truncated)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              context.tr(
                'Preview is limited. Download to view the complete file.',
              ),
            ),
          ),
        Expanded(
          child: columns == 0
              ? Center(child: Text(context.tr('This file is empty.')))
              : SingleChildScrollView(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        for (var c = 0; c < columns; c++)
                          DataColumn(label: Text((c + 1).toString())),
                      ],
                      rows: [
                        for (final row in sheet.rows)
                          DataRow(
                            cells: [
                              for (var c = 0; c < columns; c++)
                                DataCell(
                                  SizedBox(
                                    width: 180,
                                    child: SelectableText(
                                      c < row.length ? row[c] : '',
                                      maxLines: 4,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
