import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/manager_performance/domain/entities/manager_points_record.dart';
import 'package:shiftly/features/manager_performance/presentation/cubit/manager_performance_cubit.dart';
import 'package:shiftly/features/manager_performance/presentation/widgets/manager_scoped_details.dart';

class ManagerAuditDialog extends StatelessWidget {
  const ManagerAuditDialog({
    required this.record,
    required this.cubit,
    required this.scope,
    super.key,
  });
  final ManagerPointsRecord record;
  final ManagerPerformanceCubit cubit;
  final FeatureSessionScope scope;
  String _date(BuildContext context, String field) {
    final value = record.fields[field];
    final parsed = value is String ? DateTime.tryParse(value) : null;
    return parsed == null
        ? 'Unknown'
        : WorkspaceTime.dateTime(
            parsed,
            scope.timezone,
            locale: Localizations.localeOf(context).toString(),
          );
  }

  @override
  Widget build(BuildContext context) => ManagerScopedDetails(
    cubit: cubit,
    scope: scope,
    child: AlertDialog(
      title: Text(context.tr('Immutable audit record')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('ID: {value1}', {'value1': (record.id).toString()}),
            ),
            Text(
              context.tr('Reason: {value1}', {
                'value1': context.tr(record.text('reason')),
              }),
            ),
            Text(record.text('explanation')),
            Text(
              context.tr('Created: {value1}', {
                'value1': (_date(context, 'createdAt')).toString(),
              }),
            ),
            Text(
              context.tr('Actor membership: {value1}', {
                'value1': (record.text('createdByMembershipId')).toString(),
              }),
            ),
            Text(
              context.tr('Policy version: {value1}', {
                'value1': (record.text('policyVersionId')).toString(),
              }),
            ),
            if (record.reversed) ...[
              Text(
                context.tr('Reversed: {value1}', {
                  'value1': (_date(context, 'reversedAt')).toString(),
                }),
              ),
              Text(record.text('reversalReason')),
              Text(record.text('reversalExplanation')),
            ],
            if (record.fields['ledgerEntries'] case final List entries)
              for (final entry in entries.whereType<Map>())
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    context.tr(
                      '{value1} {value2} · {value3}\nEntry: {value4}',
                      {
                        'value1': context.tr(
                          '${entry['pointType'] ?? 'Unknown'}',
                        ),
                        'value2': (entry['amount'] ?? 'Unknown').toString(),
                        'value3': context.tr('${entry['reason'] ?? 'Unknown'}'),
                        'value4': (entry['id'] ?? 'Unknown').toString(),
                      },
                    ),
                  ),
                ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.tr('Close')),
        ),
        if (!record.reversed)
          FilledButton(
            onPressed: !cubit.state.canMutate
                ? null
                : () {
                    if (cubit.state.scope == scope && cubit.state.canMutate) {
                      Navigator.pop(context, true);
                    }
                  },
            child: Text(context.tr('Reverse record')),
          ),
      ],
    ),
  );
}
