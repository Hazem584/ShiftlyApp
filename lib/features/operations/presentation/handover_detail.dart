import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:uuid/uuid.dart';

import '../domain/operations_repository.dart';
import 'operations_helpers.dart';

class HandoverDetail extends StatefulWidget {
  const HandoverDetail({
    super.key,
    required this.repository,
    required this.workspaceId,
    required this.membershipId,
    required this.timezone,
    required this.manager,
    required this.isCurrent,
    required this.id,
  });
  final OperationsRepository repository;
  final String workspaceId, membershipId, timezone, id;
  final bool manager;
  final bool Function() isCurrent;
  @override
  State<HandoverDetail> createState() => _HandoverDetailState();
}

class _HandoverDetailState extends State<HandoverDetail> {
  OperationMap? _handover;
  String? _error;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final h = await widget.repository.handover(widget.workspaceId, widget.id);
      if (mounted && widget.isCurrent()) {
        setState(() {
          _handover = h;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = operationError(e));
    }
  }

  Future<void> _mutate(Future<void> Function() action) async {
    if (_busy || !widget.isCurrent()) return;
    setState(() => _busy = true);
    try {
      await action();
      if (widget.isCurrent()) await _load();
    } catch (e) {
      if (mounted) setState(() => _error = operationError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _change(OperationMap i, String status) async {
    final note = await operationNote(context);
    if (note == null || !mounted) return;
    await _mutate(
      () => widget.repository.updateItem(
        widget.workspaceId,
        widget.id,
        i['id'] as String,
        {'revision': i['revision'], 'status': status, 'note': note},
      ),
    );
  }

  Future<void> _forward() async {
    final from = WorkspaceTime.dateKey(DateTime.now(), widget.timezone);
    await _mutate(() async {
      final list = await widget.repository.occurrences(
        widget.workspaceId,
        from,
      );
      if (!mounted || !widget.isCurrent()) return;
      final target = await showDialog<String>(
        context: context,
        builder: (c) => SimpleDialog(
          title: Text(c.tr('Next receiving shift')),
          children: [
            for (final o in list.where(
              (o) => o['key'] != opMap(_handover!['target'])['key'],
            ))
              SimpleDialogOption(
                onPressed: () => Navigator.pop(c, o['key'] as String),
                child: Text(occurrenceLabel(o, widget.timezone)),
              ),
          ],
        ),
      );
      if (target == null || !mounted) return;
      final note = await operationNote(context);
      if (note == null || !widget.isCurrent()) return;
      await widget.repository.forward(widget.workspaceId, widget.id, {
        'clientId': const Uuid().v4(),
        'revision': _handover!['revision'],
        'from': from,
        'targetKey': target,
        'note': note,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final h = _handover;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Shift handover')),
        actions: [
          IconButton(
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: context.tr('Refresh'),
          ),
        ],
      ),
      body: h == null
          ? Center(
              child: _error != null
                  ? Text(_error!)
                  : const CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          occurrenceLabel(opMap(h['source']), widget.timezone),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Icon(
                            Icons.south_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 18,
                          ),
                        ),
                        Text(
                          occurrenceLabel(opMap(h['target']), widget.timezone),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Chip(label: Text(context.tr(h['status'] as String))),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (h['parent_id'] != null)
                  TextButton(
                    onPressed: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HandoverDetail(
                          repository: widget.repository,
                          workspaceId: widget.workspaceId,
                          membershipId: widget.membershipId,
                          timezone: widget.timezone,
                          manager: widget.manager,
                          isCurrent: widget.isCurrent,
                          id: h['parent_id'] as String,
                        ),
                      ),
                    ),
                    child: Text(context.tr('Previous handover history')),
                  ),
                if (h['status'] == 'WAITING_RECEIPT' &&
                    h['receiver_id'] == widget.membershipId)
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _mutate(
                            () => widget.repository.receive(
                              widget.workspaceId,
                              widget.id,
                              h['revision'] as int,
                            ),
                          ),
                    child: Text(
                      context.tr('Confirm receipt and take responsibility'),
                    ),
                  ),
                if (h['status'] == 'RECEIVED' &&
                    (widget.manager || h['receiver_id'] == widget.membershipId))
                  OutlinedButton(
                    onPressed: _busy ? null : _forward,
                    child: Text(
                      context.tr('Carry unresolved items to the next shift'),
                    ),
                  ),
                if (_error != null) Text(_error!),
                if (_busy) const LinearProgressIndicator(),
                for (final i in opRows(h['items']))
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${i['title']} · ${context.tr(i['priority'] as String)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(i['detail'] as String),
                          Text(
                            '${context.tr('Deadline')}: ${opDate(i['due_at'], widget.timezone)}',
                          ),
                          Text(
                            '${context.tr('Responsible employee')}: ${i['owner_id'] == h['receiver_id'] ? opMap(h['target'])['name'] : opMap(h['source'])['name']}',
                          ),
                          Text(
                            '${context.tr(i['status'] as String)}${i['overdue'] == true ? ' · ${context.tr('Overdue')}' : ''}',
                          ),
                          if (h['status'] != 'FORWARDED' &&
                              (widget.manager ||
                                  i['owner_id'] == widget.membershipId))
                            Wrap(
                              spacing: 8,
                              children: [
                                for (final (status, label) in [
                                  ('OPEN', 'Reopen'),
                                  ('IN_PROGRESS', 'Start work'),
                                  ('RESOLVED', 'Resolve'),
                                  ('ESCALATED', 'Escalate to manager'),
                                ])
                                  TextButton(
                                    onPressed:
                                        _busy ||
                                            i['status'] == status ||
                                            (h['status'] == 'WAITING_RECEIPT' &&
                                                (status == 'IN_PROGRESS' ||
                                                    status == 'RESOLVED'))
                                        ? null
                                        : () => _change(i, status),
                                    child: Text(context.tr(label)),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                Text(
                  context.tr('Change history'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  context.tr(
                    'Latest 200 events are shown. Earlier events remain saved.',
                  ),
                ),
                for (final e in opRows(h['events']))
                  ListTile(
                    title: Text(
                      '${context.tr(e['action'] as String)} · ${e['actorName']}',
                    ),
                    subtitle: Text(
                      '${e['note']}\n${opDate(e['created_at'], widget.timezone)}',
                    ),
                  ),
              ],
            ),
    );
  }
}
