import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import '../domain/operations_repository.dart';
import 'operations_helpers.dart';

class HandoverItemEditor extends StatefulWidget {
  const HandoverItemEditor({super.key, required this.timezone});
  final String timezone;
  @override
  State<HandoverItemEditor> createState() => _HandoverItemEditorState();
}

class _HandoverItemEditorState extends State<HandoverItemEditor> {
  final _title = TextEditingController(), _detail = TextEditingController();
  DateTime? _due;
  bool _urgent = false;
  String? _error;
  @override
  void dispose() {
    _title.dispose();
    _detail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.tr('Operational handover item')),
    content: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _title,
              maxLength: 160,
              decoration: InputDecoration(
                labelText: context.tr('Issue / unfinished work'),
              ),
            ),
            TextField(
              controller: _detail,
              maxLength: 2000,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: context.tr('Details and next action'),
              ),
            ),
            SwitchListTile(
              value: _urgent,
              onChanged: (v) => setState(() => _urgent = v),
              title: Text(context.tr('Urgent: notify the manager')),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final d = await chooseOperationTime(
                    context,
                    widget.timezone,
                    initial: DateTime.now().add(const Duration(hours: 4)),
                  );
                  if (d != null && mounted) setState(() => _due = d);
                } catch (e) {
                  if (mounted) setState(() => _error = operationError(e));
                }
              },
              child: Text(
                _due == null
                    ? context.tr('Choose deadline')
                    : opDate(_due!.toIso8601String(), widget.timezone),
              ),
            ),
            if (_error != null) Text(_error!),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.tr('Cancel')),
      ),
      FilledButton(
        onPressed: () {
          if (_title.text.trim().isEmpty || _due == null) {
            setState(
              () => _error = context.tr('Title and deadline are required'),
            );
            return;
          }
          Navigator.pop<OperationMap>(context, {
            'title': _title.text.trim(),
            'detail': _detail.text.trim(),
            'dueAt': _due!.toIso8601String(),
            'priority': _urgent ? 'URGENT' : 'NORMAL',
          });
        },
        child: Text(context.tr('Add')),
      ),
    ],
  );
}
