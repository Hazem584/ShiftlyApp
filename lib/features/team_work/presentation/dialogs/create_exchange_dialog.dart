import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shiftly/core/error/api_error_parser.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/team_work/domain/shift_exchange.dart';
import 'package:shiftly/features/team_work/domain/shift_exchange_repository.dart';
import 'package:uuid/uuid.dart';

class CreateExchangeDialog extends StatefulWidget {
  const CreateExchangeDialog({
    super.key,
    required this.repository,
    required this.workspaceId,
    required this.membershipId,
    required this.timezone,
    required this.isCurrent,
  });
  final ShiftExchangeRepository repository;
  final String workspaceId, membershipId, timezone;
  final bool Function() isCurrent;
  @override
  State<CreateExchangeDialog> createState() => _CreateExchangeDialogState();
}

class _CreateExchangeDialogState extends State<CreateExchangeDialog> {
  final _reason = TextEditingController();
  List<ExchangeColleague> _colleagues = [];
  String _kind = 'SWAP';
  String? _target, _error, _clientId, _lastPayload;
  late String _dateA = _tomorrow(), _dateB = _dateA;
  Map<String, Object?>? _a, _b;
  bool _loading = true, _busy = false;
  int _generation = 0;
  String _tomorrow() {
    final d = WorkspaceTime.inWorkspace(DateTime.now(), widget.timezone);
    final next = DateTime(d.year, d.month, d.day + 1);
    return WorkspaceTime.localDateKey(
      year: next.year,
      month: next.month,
      day: next.day,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadColleagues();
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _loadColleagues() async {
    try {
      final colleagues = <ExchangeColleague>[];
      for (var p = 1; ; p++) {
        final result = await widget.repository.colleagues(
          widget.workspaceId,
          page: p,
        );
        if (!mounted || !widget.isCurrent()) return;
        colleagues.addAll(result.items);
        if (colleagues.length >= result.total || result.items.isEmpty) break;
      }
      setState(() {
        _loading = false;
        _colleagues = colleagues;
      });
    } catch (e) {
      if (mounted && widget.isCurrent()) {
        setState(() {
          _loading = false;
          _error = ApiErrorParser.parse(e).message;
        });
      }
    }
  }

  void _invalidate() {
    _generation++;
    _a = null;
    _b = null;
    _error = null;
  }

  Future<void> _date(bool requester) async {
    final local = WorkspaceTime.inWorkspace(DateTime.now(), widget.timezone),
        selected = DateTime.parse(requester ? _dateA : _dateB);
    final first = DateTime(local.year, local.month, local.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: selected.isBefore(first) ? first : selected,
      firstDate: first,
      lastDate: first.add(const Duration(days: 365)),
    );
    if (picked != null && mounted) {
      setState(() {
        _invalidate();
        final key = WorkspaceTime.localDateKey(
          year: picked.year,
          month: picked.month,
          day: picked.day,
        );
        if (requester) {
          _dateA = key;
          if (_kind == 'COVER') _dateB = key;
        } else {
          _dateB = key;
        }
      });
    }
  }

  Future<void> _preview() async {
    if (_target == null || _busy || !widget.isCurrent()) return;
    final generation = ++_generation;
    setState(() {
      _busy = true;
      _error = null;
      _a = null;
      _b = null;
    });
    try {
      final result = await Future.wait([
        widget.repository.occurrence(
          widget.workspaceId,
          widget.membershipId,
          _dateA,
        ),
        widget.repository.occurrence(widget.workspaceId, _target!, _dateB),
      ]);
      if (!mounted || generation != _generation || !widget.isCurrent()) return;
      final a = result[0], b = result[1];
      if (a['expected'] != true ||
          (_kind == 'SWAP' && b['expected'] != true) ||
          (_kind == 'COVER' && b['expected'] == true)) {
        throw const FormatException(
          'A swap needs two working occurrences. Coverage needs a colleague with no baseline shift that day.',
        );
      }
      setState(() {
        _a = a;
        _b = b;
      });
    } catch (e) {
      if (mounted && generation == _generation) {
        setState(
          () => _error = e is FormatException
              ? e.message
              : ApiErrorParser.parse(e).message,
        );
      }
    } finally {
      if (mounted && generation == _generation) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (_busy ||
        _a == null ||
        _b == null ||
        _reason.text.trim().length < 5 ||
        !widget.isCurrent()) {
      return;
    }
    final payload = jsonEncode([
      _kind,
      _target,
      _dateA,
      _dateB,
      _reason.text.trim(),
      _a,
      _b,
    ]);
    if (payload != _lastPayload) {
      _lastPayload = payload;
      _clientId = const Uuid().v4();
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.repository.create(
        widget.workspaceId,
        clientId: _clientId!,
        targetMembershipId: _target!,
        kind: _kind,
        requesterDate: _dateA,
        targetDate: _dateB,
        reason: _reason.text.trim(),
        requesterSnapshot: _a!,
        targetSnapshot: _b!,
      );
      if (mounted) Navigator.pop(context, widget.isCurrent());
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = ApiErrorParser.parse(e).message;
        });
      }
    }
  }

  String _period(Map<String, Object?> evidence) {
    final timezone = (evidence['schedule'] as Map)['timezone'] as String;
    final locale = Localizations.localeOf(context).toString();
    return '${WorkspaceTime.dateTime(DateTime.parse(evidence['scheduledStartAt']! as String), timezone, locale: locale)} - ${WorkspaceTime.dateTime(DateTime.parse(evidence['scheduledEndAt']! as String), timezone, locale: locale)}';
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: AlertDialog(
      title: Text(context.tr('Request shift swap / coverage')),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr(
                  'Your colleague must accept, then a manager must approve. Your schedule stays the same until approval.',
                ),
              ),
              if (_loading) const LinearProgressIndicator(),
              DropdownButtonFormField<String>(
                initialValue: _kind,
                isExpanded: true,
                items: [
                  DropdownMenuItem(
                    value: 'SWAP',
                    child: Text(context.tr('Swap fixed shifts')),
                  ),
                  DropdownMenuItem(
                    value: 'COVER',
                    child: Text(context.tr('Ask a colleague to cover')),
                  ),
                ],
                onChanged: _busy || _loading
                    ? null
                    : (v) => setState(() {
                        _invalidate();
                        _kind = v!;
                        if (_kind == 'COVER') _dateB = _dateA;
                      }),
              ),
              DropdownButtonFormField<String>(
                initialValue: _target,
                isExpanded: true,
                decoration: InputDecoration(labelText: context.tr('Colleague')),
                items: [
                  for (final c in _colleagues)
                    DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: _busy || _loading
                    ? null
                    : (v) => setState(() {
                        _invalidate();
                        _target = v;
                      }),
              ),
              OutlinedButton(
                onPressed: _busy ? null : () => _date(true),
                child: Text('${context.tr('Your operational date')}: $_dateA'),
              ),
              if (_kind == 'SWAP')
                OutlinedButton(
                  onPressed: _busy ? null : () => _date(false),
                  child: Text(
                    '${context.tr('Colleague operational date')}: $_dateB',
                  ),
                ),
              OutlinedButton(
                onPressed: _busy || _target == null ? null : _preview,
                child: Text(context.tr('Preview agreed schedules')),
              ),
              if (_a != null && _b != null) ...[
                Text(
                  '${_a!['name']} · $_dateA · ${(_a!['schedule'] as Map)['name']}',
                ),
                Text(_period(_a!)),
                Text(
                  '${_b!['name']} · $_dateB · ${_b!['expected'] == true ? (_b!['schedule'] as Map)['name'] : context.tr('Day off')}',
                ),
                if (_b!['expected'] == true) Text(_period(_b!)),
                Text(
                  context.tr('After approval: {employee} works {shift}', {
                    'employee': _b!['name']! as String,
                    'shift': (_a!['schedule'] as Map)['name'] as String,
                  }),
                ),
                Text(
                  _kind == 'COVER'
                      ? context.tr('After approval: {employee} has a day off', {
                          'employee': _a!['name']! as String,
                        })
                      : context.tr('After approval: {employee} works {shift}', {
                          'employee': _a!['name']! as String,
                          'shift': (_b!['schedule'] as Map)['name'] as String,
                        }),
                ),
              ],
              TextField(
                controller: _reason,
                enabled: !_busy,
                minLines: 2,
                maxLines: 4,
                maxLength: 1000,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: context.tr('Reason (at least 5 characters)'),
                ),
              ),
              if (_error != null)
                Text(
                  context.tr(_error!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: Text(context.tr('Cancel')),
        ),
        FilledButton(
          onPressed:
              _busy ||
                  _a == null ||
                  _b == null ||
                  _reason.text.trim().length < 5
              ? null
              : _save,
          child: Text(context.tr('Send request')),
        ),
      ],
    ),
  );
}
