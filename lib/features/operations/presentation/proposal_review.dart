import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import '../domain/operations_repository.dart';
import 'operations_helpers.dart';

class ProposalReview extends StatefulWidget {
  const ProposalReview({
    super.key,
    required this.repository,
    required this.workspaceId,
    required this.timezone,
    required this.draft,
    required this.isCurrent,
    required this.onApplied,
  });
  final OperationsRepository repository;
  final String workspaceId, timezone;
  final OperationMap draft;
  final bool Function() isCurrent;
  final ValueChanged<OperationMap> onApplied;
  @override
  State<ProposalReview> createState() => _ProposalReviewState();
}

class _ProposalReviewState extends State<ProposalReview> {
  late final List<String?> _choices;
  final _note = TextEditingController();
  bool _shortage = false, _busy = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _choices = opRows(opMap(widget.draft['result'])['seats'])
        .map((s) => s['memberId'] as String?)
        .toList();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _approve() async {
    if (!widget.isCurrent()) return;
    setState(() => _busy = true);
    try {
      final d = await widget.repository.approve(
        widget.workspaceId,
        widget.draft['id'] as String,
        {
          'choices': _choices,
          'acceptShortage': _shortage,
          'note': _note.text.trim(),
        },
      );
      if (mounted && widget.isCurrent()) widget.onApplied(d);
    } catch (e) {
      if (mounted) setState(() => _error = operationError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = opMap(widget.draft['result']),
        seats = opRows(result['seats']),
        members = opRows(result['members']),
        demands = opRows(opMap(widget.draft['input'])['demands']);
    final applied = widget.draft['status'] == 'APPLIED';
    String name(Object? id) =>
        members
            .where((m) => m['id'] == id)
            .map((m) => m['name'] as String)
            .firstOrNull ??
        context.tr('Uncovered');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr(
                applied ? 'Schedule published' : 'Review before publishing',
              ),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              '${context.tr('Uncovered positions')}: ${_choices.where((c) => c == null).length}',
            ),
            for (final (i, s) in seats.indexed)
              ExpansionTile(
                title: Text(
                  '${demands[s['demand'] as int]['label']} · ${name(s['memberId'])}',
                ),
                subtitle: Text(
                  '${opDate(demands[s['demand'] as int]['startsAt'], widget.timezone)}\n${context.tr('Original recommendation')}',
                ),
                children: [
                  for (final reason in (s['reasons'] as List).cast<String>())
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(planningReason(context, reason)),
                    ),
                  if (!applied)
                    DropdownButtonFormField<String>(
                      initialValue: _choices[i] ?? '',
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.tr('Manager selection'),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: '',
                          child: Text(context.tr('Uncovered')),
                        ),
                        for (final m in members)
                          DropdownMenuItem(
                            value: m['id'] as String,
                            child: Text(m['name'] as String),
                          ),
                      ],
                      onChanged: _busy
                          ? null
                          : (v) => setState(
                              () => _choices[i] = v == '' ? null : v,
                            ),
                    ),
                  for (final rejected in opRows(s['rejected']))
                    ListTile(
                      dense: true,
                      title: Text(name(rejected['memberId'])),
                      subtitle: Text(
                        (rejected['reasons'] as List)
                            .cast<String>()
                            .map((r) => planningReason(context, r))
                            .join(' · '),
                      ),
                    ),
                ],
              ),
            if (!applied) ...[
              CheckboxListTile(
                value: _shortage,
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _shortage = v ?? false),
                title: Text(
                  context.tr(
                    'I accept the uncovered positions and will arrange coverage',
                  ),
                ),
              ),
              TextField(
                controller: _note,
                maxLength: 1000,
                decoration: InputDecoration(
                  labelText: context.tr(
                    'Approval note (required for shortage)',
                  ),
                ),
              ),
              if (_error != null) Text(_error!),
              FilledButton(
                onPressed: _busy ? null : _approve,
                child: Text(
                  context.tr(
                    _busy ? 'Publishing…' : 'Approve and publish shifts',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
