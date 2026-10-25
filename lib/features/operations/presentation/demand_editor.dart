import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import '../domain/operations_repository.dart';
import 'operations_helpers.dart';

class DemandEditor extends StatefulWidget {
  const DemandEditor({super.key, required this.timezone});
  final String timezone;
  @override
  State<DemandEditor> createState() => _DemandEditorState();
}

class _DemandEditorState extends State<DemandEditor> {
  final _form = GlobalKey<FormState>(),
      _label = TextEditingController(),
      _count = TextEditingController(text: '1'),
      _skills = TextEditingController(),
      _break = TextEditingController(text: '60');
  DateTime? _from, _to;
  String? _error;
  @override
  void dispose() {
    _label.dispose();
    _count.dispose();
    _skills.dispose();
    _break.dispose();
    super.dispose();
  }

  Future<void> _time(bool from) async {
    try {
      final t = await chooseOperationTime(
        context,
        widget.timezone,
        initial: from ? _from : _to ?? _from?.add(const Duration(hours: 9)),
      );
      if (t != null && mounted) {
        setState(() {
          if (from) {
            _from = t;
          } else {
            _to = t;
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = operationError(e));
    }
  }

  void _done() {
    if (!_form.currentState!.validate()) return;
    if (_from == null || _to == null || !_to!.isAfter(_from!)) {
      setState(() => _error = context.tr('Choose a start and a later end'));
      return;
    }
    Navigator.pop<OperationMap>(context, {
      'label': _label.text.trim(),
      'startsAt': _from!.toIso8601String(),
      'endsAt': _to!.toIso8601String(),
      'count': int.parse(_count.text),
      'breakMinutes': int.parse(_break.text),
      'skills': _skills.text
          .split(',')
          .map((s) => s.trim().toLowerCase())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList(),
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.tr('Add staffing requirement')),
    content: SizedBox(
      width: 480,
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${context.tr('Times use workspace timezone')}: ${widget.timezone}',
              ),
              TextFormField(
                controller: _label,
                maxLength: 80,
                decoration: InputDecoration(
                  labelText: context.tr('Shift / role name'),
                ),
                validator: (v) =>
                    v!.trim().isEmpty ? context.tr('Required') : null,
              ),
              TextFormField(
                controller: _count,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.tr('Employees required (1–20)'),
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return n == null || n < 1 || n > 20
                      ? context.tr('Enter a value within the allowed range')
                      : null;
                },
              ),
              TextFormField(
                controller: _skills,
                decoration: InputDecoration(
                  labelText: context.tr(
                    'Skills (comma separated: leader, cashier)',
                  ),
                ),
                validator: (v) =>
                    v!
                        .split(',')
                        .where((s) => s.trim().isNotEmpty)
                        .any(
                          (s) =>
                              !RegExp(r'^[a-z0-9_-]{1,40}$')
                                  .hasMatch(s.trim().toLowerCase()),
                        )
                    ? context.tr('Use short English skill codes')
                    : null,
              ),
              TextFormField(
                controller: _break,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.tr(
                    'Break minutes (at least 60 for long shifts)',
                  ),
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  return n == null || n < 0 || n > 120
                      ? context.tr('Enter a value within the allowed range')
                      : null;
                },
              ),
              TextButton(
                onPressed: () => _time(true),
                child: Text(
                  _from == null
                      ? context.tr('Choose start')
                      : opDate(_from!.toIso8601String(), widget.timezone),
                ),
              ),
              TextButton(
                onPressed: () => _time(false),
                child: Text(
                  _to == null
                      ? context.tr('Choose end')
                      : opDate(_to!.toIso8601String(), widget.timezone),
                ),
              ),
              if (_error != null) Text(_error!),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.tr('Cancel')),
      ),
      FilledButton(onPressed: _done, child: Text(context.tr('Add'))),
    ],
  );
}
