import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:uuid/uuid.dart';

import '../domain/operations_repository.dart';
import 'handover_item_editor.dart';
import 'operations_helpers.dart';

class HandoverEditor extends StatefulWidget {
  const HandoverEditor({
    super.key,
    required this.repository,
    required this.workspaceId,
    required this.membershipId,
    required this.timezone,
    required this.manager,
    required this.isCurrent,
  });
  final OperationsRepository repository;
  final String workspaceId, membershipId, timezone;
  final bool manager;
  final bool Function() isCurrent;
  @override
  State<HandoverEditor> createState() => _HandoverEditorState();
}

class _HandoverEditorState extends State<HandoverEditor> {
  List<OperationMap> _occurrences = [];
  final List<OperationMap> _items = [];
  String? _source, _target, _error;
  bool _loading = true, _busy = false;
  late String _from;
  String _clientId = const Uuid().v4();
  @override
  void initState() {
    super.initState();
    _from = WorkspaceTime.dateKey(DateTime.now(), widget.timezone);
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await widget.repository.occurrences(widget.workspaceId, _from);
      if (mounted && widget.isCurrent()) setState(() => _occurrences = r);
    } catch (e) {
      if (mounted) setState(() => _error = operationError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_source == null || _target == null || _items.isEmpty) {
      setState(
        () =>
            _error = context.tr('Choose both shifts and add at least one item'),
      );
      return;
    }
    if (!widget.isCurrent()) return;
    setState(() => _busy = true);
    try {
      final h = await widget.repository.createHandover(widget.workspaceId, {
        'clientId': _clientId,
        'from': _from,
        'sourceKey': _source,
        'targetKey': _target,
        'items': _items,
      });
      if (mounted && widget.isCurrent()) {
        Navigator.pop(context, h['id'] as String);
      }
    } catch (e) {
      if (mounted) setState(() => _error = operationError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.tr('Create shift handover')),
    content: SizedBox(
      width: 650,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_loading) const CircularProgressIndicator(),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _source,
              decoration: InputDecoration(
                labelText: context.tr('Sending shift'),
              ),
              items: [
                for (final o in _occurrences.where(
                  (o) => widget.manager || o['memberId'] == widget.membershipId,
                ))
                  DropdownMenuItem(
                    value: o['key'] as String,
                    child: Text(
                      occurrenceLabel(o, widget.timezone),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: _busy
                  ? null
                  : (v) => setState(() {
                      _source = v;
                      _target = null;
                      _clientId = const Uuid().v4();
                    }),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey(_source),
              isExpanded: true,
              initialValue: _target,
              decoration: InputDecoration(
                labelText: context.tr('Receiving shift'),
              ),
              items: [
                for (final o in _occurrences.where((o) => o['key'] != _source))
                  DropdownMenuItem(
                    value: o['key'] as String,
                    child: Text(
                      occurrenceLabel(o, widget.timezone),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: _busy
                  ? null
                  : (v) => setState(() {
                      _target = v;
                      _clientId = const Uuid().v4();
                    }),
            ),
            for (final (i, item) in _items.indexed)
              ListTile(
                title: Text(item['title'] as String),
                subtitle: Text(opDate(item['dueAt'], widget.timezone)),
                trailing: IconButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _items.removeAt(i);
                          _clientId = const Uuid().v4();
                        }),
                  icon: const Icon(Icons.delete_outline),
                ),
              ),
            OutlinedButton(
              onPressed: _busy || _items.length >= 30
                  ? null
                  : () async {
                      final i = await showDialog<OperationMap>(
                        context: context,
                        builder: (_) =>
                            HandoverItemEditor(timezone: widget.timezone),
                      );
                      if (i != null && mounted) {
                        setState(() {
                          _items.add(i);
                          _clientId = const Uuid().v4();
                        });
                      }
                    },
              child: Text(context.tr('Add handover item')),
            ),
            if (_error != null) Text(_error!),
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
        onPressed: _busy || _loading ? null : _save,
        child: Text(context.tr('Send handover')),
      ),
    ],
  );
}
