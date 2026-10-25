import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:uuid/uuid.dart';

import '../domain/operations_repository.dart';
import 'demand_editor.dart';
import 'operations_helpers.dart';
import 'proposal_review.dart';

class PlanningView extends StatefulWidget {
  const PlanningView({
    super.key,
    required this.repository,
    required this.workspaceId,
    required this.timezone,
    required this.isCurrent,
  });
  final OperationsRepository repository;
  final String workspaceId, timezone;
  final bool Function() isCurrent;
  @override
  State<PlanningView> createState() => _PlanningViewState();
}

class _PlanningViewState extends State<PlanningView> {
  final List<OperationMap> _demands = [];
  List<OperationMap> _history = [];
  OperationMap? _draft;
  String? _error;
  bool _busy = false;
  late String _week;
  String _clientId = const Uuid().v4();
  @override
  void initState() {
    super.initState();
    final now = WorkspaceTime.inWorkspace(DateTime.now(), widget.timezone);
    final saturday = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(Duration(days: (DateTime.saturday - now.weekday + 7) % 7));
    _week = WorkspaceTime.localDateKey(
      year: saturday.year,
      month: saturday.month,
      day: saturday.day,
    );
    _load();
  }

  Future<void> _load() async {
    try {
      final h = await widget.repository.proposals(widget.workspaceId);
      if (mounted && widget.isCurrent()) setState(() => _history = h);
    } catch (e) {
      if (mounted) setState(() => _error = operationError(e));
    }
  }

  Future<void> _generate() async {
    if (_busy || !widget.isCurrent()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final d = await widget.repository.generate(widget.workspaceId, {
        'clientId': _clientId,
        'weekStart': _week,
        'demands': _demands,
      });
      if (mounted && widget.isCurrent()) {
        setState(() {
          _draft = d;
          _clientId = const Uuid().v4();
        });
      }
      await _load();
    } catch (e) {
      if (mounted) setState(() => _error = operationError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(
        context.tr(
          'Reviewable suggestions, never automatic publication. Mandatory constraints cannot be overridden.',
        ),
      ),
      Text(
        context.tr(
          'For five staff including one leader, add one leader position and four general positions for the same shift.',
        ),
      ),
      Text(
        context.tr(
          'Scheduled headcount does not include cover during breaks. Arrange staggered breaks or add relief coverage.',
        ),
      ),
      TextButton(
        onPressed: _busy
            ? null
            : () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.parse(_week),
                  firstDate: DateTime.now().subtract(const Duration(days: 7)),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                );
                if (date == null || !mounted) return;
                if (date.weekday != DateTime.saturday) {
                  setState(() => _error = context.tr('Choose a Saturday'));
                  return;
                }
                setState(() {
                  _week = WorkspaceTime.localDateKey(
                    year: date.year,
                    month: date.month,
                    day: date.day,
                  );
                  _clientId = const Uuid().v4();
                });
              },
        child: Text('${context.tr('Week starts Saturday')}: $_week'),
      ),
      for (final (i, d) in _demands.indexed)
        Card(
          child: ListTile(
            title: Text('${d['label']} × ${d['count']}'),
            subtitle: Text(
              '${opDate(d['startsAt'], widget.timezone)} → ${opDate(d['endsAt'], widget.timezone)}\n${(d['skills'] as List).join(', ')}',
            ),
            trailing: IconButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _demands.removeAt(i);
                      _clientId = const Uuid().v4();
                    }),
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        ),
      Wrap(
        spacing: 12,
        children: [
          OutlinedButton(
            onPressed: _busy || _demands.length >= 40
                ? null
                : () async {
                    final d = await showDialog<OperationMap>(
                      context: context,
                      builder: (_) => DemandEditor(timezone: widget.timezone),
                    );
                    if (d != null && mounted) {
                      setState(() {
                        _demands.add(d);
                        _clientId = const Uuid().v4();
                      });
                    }
                  },
            child: Text(context.tr('Add staffing requirement')),
          ),
          FilledButton(
            onPressed: _busy || _demands.isEmpty ? null : _generate,
            child: Text(
              context.tr(_busy ? 'Generating…' : 'Generate proposal'),
            ),
          ),
          TextButton(
            onPressed: _busy ? null : _load,
            child: Text(context.tr('Refresh')),
          ),
        ],
      ),
      if (_error != null) Text(_error!),
      if (_draft != null)
        ProposalReview(
          key: ValueKey('${_draft!['id']}:${_draft!['status']}'),
          repository: widget.repository,
          workspaceId: widget.workspaceId,
          timezone: widget.timezone,
          draft: _draft!,
          isCurrent: widget.isCurrent,
          onApplied: (d) {
            setState(() => _draft = d);
            _load();
          },
        ),
      const Divider(),
      Text(context.tr('Recent proposals')),
      for (final h in _history)
        ListTile(
          title: Text('${opMap(h['input'])['weekStart']} · ${h['status']}'),
          subtitle: Text(
            '${context.tr('Uncovered positions')}: ${opMap(h['result'])['shortage']}',
          ),
          onTap: _busy ? null : () => setState(() => _draft = h),
        ),
    ],
  );
}
