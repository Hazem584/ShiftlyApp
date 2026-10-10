import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
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
      return context.tr('Unknown');
    }
    final parsed = DateTime.tryParse(value);
    return parsed == null
        ? context.tr('Unknown')
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
        Text(context.tr(state.error!)),
        TextButton(
          onPressed: state.loading ? null : reload,
          child: Text(context.tr('Retry')),
        ),
      ],
      if (!state.loading && state.records.isEmpty && state.error == null)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text(context.tr('No records for this selection.')),
        ),
      if (['warnings', 'extra-effort', 'adjustments'].contains(resource))
        Text(context.tr('Showing up to the 100 most recent server records.')),
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
          child: Text(context.tr('Load more')),
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
          name is String ? name : context.tr('Employee'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          context.tr('GREEN available: {value1} · Active RED: {value2}', {
            'value1': (record.text('greenAvailable')).toString(),
            'value2': (record.text('redActive')).toString(),
          }),
        ),
        Text(
          context.tr(
            'BLACK total: {value1} · ORANGE total: {value2} · BLUE total: {value3}',
            {
              'value1': (total('black')).toString(),
              'value2': (total('orange')).toString(),
              'value3': (total('blue')).toString(),
            },
          ),
        ),
        Text(
          context.tr('Achievements: {value1}', {
            'value1': (record.text('achievementCount')).toString(),
          }),
        ),
        OutlinedButton.icon(
          onPressed: () =>
              context.push('/dashboard/performance/employees/${record.id}'),
          icon: const Icon(Icons.insights_outlined),
          label: Text(context.tr('Employee Performance')),
        ),
      ];
    }
    if (resource == 'policies') {
      return [
        Text(
          context.tr('Effective {value1} – {value2}', {
            'value1': (record.text('effectiveFrom')).toString(),
            'value2': (record.fields['effectiveTo'] ?? context.tr('open ended'))
                .toString(),
          }),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          context.tr('Version ID: {value1}', {
            'value1': (record.id).toString(),
          }),
        ),
        ExpansionTile(
          title: Text(context.tr('Policy settings')),
          children: [
            for (final field in ManagerForms.policy.where(
              (field) => !field.date,
            ))
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  context.tr('{value1}: {value2}', {
                    'value1': context.tr(field.label),
                    'value2': context.tr(record.text(field.key)),
                  }),
                ),
              ),
          ],
        ),
      ];
    }
    if (resource == 'warnings') {
      return [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded),
            const SizedBox(width: 8),
            Expanded(child: Text(context.tr('BLACK warning'))),
          ],
        ),
        Text(
          context.tr('Cycle: {value1} · Threshold: {value2}', {
            'value1': (record.text('cycle')).toString(),
            'value2': (record.text('threshold')).toString(),
          }),
        ),
        Text(_date(context, record, 'createdAt')),
        if (record.fields['employeeMembershipId'] is String)
          TextButton(
            onPressed: () => context.push(
              '/dashboard/performance/employees/${record.fields['employeeMembershipId']}',
            ),
            child: Text(context.tr('Employee Performance')),
          ),
      ];
    }
    if (resource == 'disputes') {
      return [
        Text(
          context.tr('Status: {value1}', {
            'value1': context.tr(record.text('status')),
          }),
        ),
        Text(record.text('reason')),
        Text(_date(context, record, 'createdAt')),
        OutlinedButton(
          onPressed: () => onRecord?.call(record),
          child: Text(context.tr('View dispute')),
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
                context.tr('{value1} {value2}', {
                  'value1': (record.text('amount')).toString(),
                  'value2': context.tr(known ? type : 'Unknown point type'),
                }),
              ),
            ),
          ],
        ),
        Text(
          Localizations.localeOf(context).languageCode == 'ar'
              ? context.tr(record.text('reason'))
              : record.text('reason').replaceAll('_', ' '),
        ),
        Text(
          record.fields['operationalDate'] is String
              ? record.text('operationalDate')
              : _date(context, record, 'createdAt'),
        ),
        if (record.fields['reversedEntryId'] != null)
          Text(
            context.tr('Reverses entry {value1}', {
              'value1': (record.text('reversedEntryId')).toString(),
            }),
          ),
      ];
    }
    return [
      Text(
        resource == 'extra-effort'
            ? context.tr('BLUE {value1} · Linked GREEN {value2}', {
                'value1': (record.text('bluePoints')).toString(),
                'value2': (record.text('greenBonus')).toString(),
              })
            : context.tr('{value1} {value2}', {
                'value1': (record.text('amount')).toString(),
                'value2': context.tr(record.text('pointType')),
              }),
      ),
      Text(
        Localizations.localeOf(context).languageCode == 'ar'
            ? context.tr(record.text('reason'))
            : record.text('reason').replaceAll('_', ' '),
      ),
      Text(record.text('explanation')),
      Text(_date(context, record, 'createdAt')),
      if (record.reversed) ...[
        Text(
          context.tr('Reversed: {value1}', {
            'value1': (_date(context, record, 'reversedAt')).toString(),
          }),
        ),
        Text(record.text('reversalReason')),
        Text(record.text('reversalExplanation')),
      ],
      if (onRecord != null)
        OutlinedButton(
          onPressed: () => onRecord?.call(record),
          child: Text(
            resource == 'adjustments'
                ? context.tr('Details / reversal')
                : record.reversed
                ? context.tr('View record')
                : context.tr('Reverse award'),
          ),
        ),
    ];
  }
}
