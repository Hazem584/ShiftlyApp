import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import '../domain/operations_repository.dart';
import 'handover_detail.dart';
import 'handover_editor.dart';
import 'operations_helpers.dart';

class HandoversView extends StatefulWidget {
  const HandoversView({
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
  State<HandoversView> createState() => _HandoversViewState();
}

class _HandoversViewState extends State<HandoversView> {
  List<OperationMap> _rows = [];
  bool _loading = true, _next = false;
  int _page = 1;
  String? _error;
  Timer? _refresh;
  @override
  void initState() {
    super.initState();
    _load();
    _refresh = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!_loading &&
          mounted &&
          widget.isCurrent() &&
          WidgetsBinding.instance.lifecycleState != AppLifecycleState.paused) {
        unawaited(_load());
      }
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await widget.repository.handovers(widget.workspaceId, _page);
      if (mounted && widget.isCurrent()) {
        setState(() {
          _rows = opRows(r['data']);
          _next = r['hasNext'] == true;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = operationError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _detail(String id) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => HandoverDetail(
          repository: widget.repository,
          workspaceId: widget.workspaceId,
          membershipId: widget.membershipId,
          timezone: widget.timezone,
          manager: widget.manager,
          isCurrent: widget.isCurrent,
          id: id,
        ),
      ),
    );
    if (mounted && widget.isCurrent()) _load();
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(
        context.tr(
          'Responsibility stays with the sender until the receiving employee confirms receipt. Overdue items are visible to the manager immediately.',
        ),
      ),
      Wrap(
        spacing: 8,
        children: [
          FilledButton.icon(
            onPressed: _loading
                ? null
                : () async {
                    final id = await showDialog<String>(
                      context: context,
                      builder: (_) => HandoverEditor(
                        repository: widget.repository,
                        workspaceId: widget.workspaceId,
                        membershipId: widget.membershipId,
                        timezone: widget.timezone,
                        manager: widget.manager,
                        isCurrent: widget.isCurrent,
                      ),
                    );
                    if (id != null && mounted && widget.isCurrent()) {
                      await _detail(id);
                    }
                  },
            icon: const Icon(Icons.add_task),
            label: Text(context.tr('Create shift handover')),
          ),
          TextButton(
            onPressed: _loading ? null : _load,
            child: Text(context.tr('Refresh')),
          ),
        ],
      ),
      if (_loading) const Center(child: CircularProgressIndicator()),
      if (_error != null) Text(_error!),
      if (!_loading && _rows.isEmpty)
        Text(context.tr('No shift handovers yet')),
      for (final h in _rows)
        Card(
          child: ListTile(
            title: Text(
              '${opMap(h['source'])['name']} → ${opMap(h['target'])['name']}',
            ),
            subtitle: Text(
              '${opDate(opMap(h['target'])['startsAt'], widget.timezone)}\n${context.tr(h['status'] as String)} · ${context.tr('Open items')}: ${h['openCount']} · ${context.tr('Overdue')}: ${h['overdueCount']}',
            ),
            trailing: Icon(
              (h['overdueCount'] as num? ?? 0) > 0
                  ? Icons.warning_amber
                  : Icons.chevron_right,
            ),
            onTap: () => _detail(h['id'] as String),
          ),
        ),
      Row(
        children: [
          TextButton(
            onPressed: _loading || _page == 1
                ? null
                : () {
                    _page--;
                    _load();
                  },
            child: Text(context.tr('Previous')),
          ),
          Text('$_page'),
          TextButton(
            onPressed: _loading || !_next
                ? null
                : () {
                    _page++;
                    _load();
                  },
            child: Text(context.tr('Next')),
          ),
        ],
      ),
    ],
  );
}
