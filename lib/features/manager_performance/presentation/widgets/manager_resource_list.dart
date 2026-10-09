import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/manager_performance/domain/entities/manager_points_record.dart';
import 'package:shiftly/features/manager_performance/presentation/cubit/manager_resource_state.dart';
import 'package:shiftly/features/manager_performance/presentation/widgets/manager_forms.dart';

class ManagerResourceList extends StatelessWidget {
  const ManagerResourceList({
    required this.resource,
    required this.state,
    required this.timezone,
    required this.reload,
    this.more,
    this.onRecord,
    super.key,
  });
  final String resource, timezone;
  final ManagerResourceState state;
  final VoidCallback reload;
  final VoidCallback? more;
  final void Function(ManagerPointsRecord)? onRecord;
  String _date(BuildContext context, ManagerPointsRecord record, String key) {
    final value = record.fields[key];
    if (value is! String) {
      return 'Unknown';
    }
    final parsed = DateTime.tryParse(value);
    return parsed == null
        ? 'Unknown'
        : WorkspaceTime.dateTime(
            parsed,
            timezone,
            locale: Localizations.localeOf(context).toString(),
          );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (state.loading) const LinearProgressIndicator(),
      if (state.error != null) ...[
        Text(state.error!),
        TextButton(
          onPressed: state.loading ? null : reload,
          child: const Text('Retry'),
        ),
      ],
      if (!state.loading && state.records.isEmpty && state.error == null)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Text('No records for this selection.'),
        ),
      if (['warnings', 'extra-effort', 'adjustments'].contains(resource))
        const Text('Showing up to the 100 most recent server records.'),
      for (final record in state.records)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _content(context, record),
            ),
          ),
        ),
      if (state.hasMore)
        TextButton(
          onPressed: state.loading ? null : more,
          child: const Text('Load more'),
        ),
    ],
  );
  List<Widget> _content(BuildContext context, ManagerPointsRecord record) {
    if (resource == 'summary') {
      final profile = record.fields['profile'];
      final name = profile is Map ? profile['fullName'] : null;
      String total(String key) {
        final balance = record.fields[key];
        return balance is Map && balance['total'] is int
            ? '${balance['total']}'
            : 'Unknown';
      }

      return [
        Text(
          name is String ? name : 'Employee',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          'GREEN available: ${record.text('greenAvailable')} · Active RED: ${record.text('redActive')}',
        ),
        Text(
          'BLACK total: ${total('black')} · ORANGE total: ${total('orange')} · BLUE total: ${total('blue')}',
        ),
        Text('Achievements: ${record.text('achievementCount')}'),
        OutlinedButton.icon(
          onPressed: () =>
              context.push('/dashboard/performance/employees/${record.id}'),
          icon: const Icon(Icons.insights_outlined),
          label: const Text('Employee Performance'),
        ),
      ];
    }
    if (resource == 'policies') {
      return [
        Text(
          'Effective ${record.text('effectiveFrom')} – ${record.fields['effectiveTo'] ?? 'open ended'}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text('Version ID: ${record.id}'),
        ExpansionTile(
          title: const Text('Policy settings'),
          children: [
            for (final field in ManagerForms.policy.where(
              (field) => !field.date,
            ))
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text('${field.label}: ${record.text(field.key)}'),
              ),
          ],
        ),
      ];
    }
    if (resource == 'warnings') {
      return [
        const Row(
          children: [
            Icon(Icons.warning_amber_rounded),
            SizedBox(width: 8),
            Expanded(child: Text('BLACK warning')),
          ],
        ),
        Text(
          'Cycle: ${record.text('cycle')} · Threshold: ${record.text('threshold')}',
        ),
        Text(_date(context, record, 'createdAt')),
        if (record.fields['employeeMembershipId'] is String)
          TextButton(
            onPressed: () => context.push(
              '/dashboard/performance/employees/${record.fields['employeeMembershipId']}',
            ),
            child: const Text('Employee Performance'),
          ),
      ];
    }
    if (resource == 'disputes') {
      return [
        Text('Status: ${record.text('status')}'),
        Text(record.text('reason')),
        Text(_date(context, record, 'createdAt')),
        OutlinedButton(
          onPressed: () => onRecord?.call(record),
          child: const Text('View dispute'),
        ),
      ];
    }
    if (resource == 'history') {
      final type = record.text('pointType');
      final known = {'GREEN', 'BLACK', 'RED', 'ORANGE', 'BLUE'}.contains(type);
      return [
        Row(
          children: [
            const Icon(Icons.receipt_long_outlined),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${record.text('amount')} ${known ? type : 'Unknown point type'}',
              ),
            ),
          ],
        ),
        Text(record.text('reason').replaceAll('_', ' ')),
        Text(
          record.fields['operationalDate'] is String
              ? record.text('operationalDate')
              : _date(context, record, 'createdAt'),
        ),
        if (record.fields['reversedEntryId'] != null)
          Text('Reverses entry ${record.text('reversedEntryId')}'),
      ];
    }
    return [
      Text(
        resource == 'extra-effort'
            ? 'BLUE ${record.text('bluePoints')} · Linked GREEN ${record.text('greenBonus')}'
            : '${record.text('amount')} ${record.text('pointType')}',
      ),
      Text(record.text('reason').replaceAll('_', ' ')),
      Text(record.text('explanation')),
      Text(_date(context, record, 'createdAt')),
      if (record.reversed) ...[
        Text('Reversed: ${_date(context, record, 'reversedAt')}'),
        Text(record.text('reversalReason')),
        Text(record.text('reversalExplanation')),
      ],
      if (onRecord != null)
        OutlinedButton(
          onPressed: () => onRecord?.call(record),
          child: Text(
            resource == 'adjustments'
                ? 'Details / reversal'
                : record.reversed
                ? 'View record'
                : 'Reverse award',
          ),
        ),
    ];
  }
}
