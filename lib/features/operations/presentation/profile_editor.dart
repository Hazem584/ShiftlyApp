import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import '../domain/operations_repository.dart';
import 'operations_helpers.dart';

class ProfileEditor extends StatefulWidget {
  const ProfileEditor({
    super.key,
    required this.repository,
    required this.workspaceId,
    required this.timezone,
    required this.profile,
    required this.isCurrent,
  });
  final OperationsRepository repository;
  final String workspaceId, timezone;
  final OperationMap profile;
  final bool Function() isCurrent;
  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _skills, _hours, _rest;
  late List<OperationMap> _windows;
  bool _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _skills = TextEditingController(
      text: (p['skills'] as List?)?.join(', ') ?? '',
    );
    _hours = TextEditingController(
      text: ((p['max_weekly_minutes'] as num? ?? 2880) / 60).toString(),
    );
    _rest = TextEditingController(
      text: ((p['min_rest_minutes'] as num? ?? 720) / 60).toString(),
    );
    _windows = opRows(p['availability'] ?? []);
  }

  @override
  void dispose() {
    _skills.dispose();
    _hours.dispose();
    _rest.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    try {
      final from = await chooseOperationTime(context, widget.timezone);
      if (from == null || !mounted) return;
      final to = await chooseOperationTime(
        context,
        widget.timezone,
        initial: from.add(const Duration(hours: 9)),
      );
      if (to == null || !mounted) return;
      if (!to.isAfter(from)) {
        throw const FormatException('End must follow start');
      }
      setState(
        () => _windows.add({
          'startsAt': from.toIso8601String(),
          'endsAt': to.toIso8601String(),
        }),
      );
    } catch (e) {
      if (mounted) setState(() => _error = operationError(e));
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate() || !widget.isCurrent()) return;
    setState(() => _busy = true);
    try {
      final skills = _skills.text
          .split(',')
          .map((s) => s.trim().toLowerCase())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();
      await widget.repository.saveProfile(
        widget.workspaceId,
        widget.profile['id'] as String,
        {
          'skills': skills,
          'availability': _windows,
          'maxWeeklyMinutes': (double.parse(_hours.text) * 60).round(),
          'minRestMinutes': (double.parse(_rest.text) * 60).round(),
          'revision': widget.profile['revision'] ?? 0,
        },
      );
      if (mounted && widget.isCurrent()) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = operationError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.profile['name'] as String),
    content: SizedBox(
      width: 540,
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
                controller: _hours,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.tr('Maximum weekly hours (1–48)'),
                ),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  return n == null || n < 1 || n > 48
                      ? context.tr('Enter a value within the allowed range')
                      : null;
                },
              ),
              TextFormField(
                controller: _rest,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.tr('Rest between shifts (12–48 hours)'),
                ),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  return n == null || n < 12 || n > 48
                      ? context.tr('Enter a value within the allowed range')
                      : null;
                },
              ),
              for (final (index, w) in _windows.indexed)
                ListTile(
                  title: Text(
                    '${opDate(w['startsAt'], widget.timezone)} → ${opDate(w['endsAt'], widget.timezone)}',
                  ),
                  trailing: IconButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _windows.removeAt(index)),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ),
              OutlinedButton(
                onPressed: _busy || _windows.length >= 100 ? null : _add,
                child: Text(context.tr('Add availability window')),
              ),
              if (_error != null) Text(_error!),
            ],
          ),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context),
        child: Text(context.tr('Cancel')),
      ),
      FilledButton(
        onPressed: _busy ? null : _save,
        child: Text(context.tr('Save')),
      ),
    ],
  );
}
