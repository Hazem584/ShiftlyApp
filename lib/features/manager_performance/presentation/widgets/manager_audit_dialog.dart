import 'package:flutter/material.dart';
import 'package:shiftly/core/session/feature_scope.dart';
import 'package:shiftly/core/utils/workspace_time.dart';

import '../../data/manager_points_record.dart';
import '../cubit/manager_performance_cubit.dart';
import 'manager_scoped_details.dart';

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
  String _date(String field) {
    final value = record.fields[field];
    final parsed = value is String ? DateTime.tryParse(value) : null;
    return parsed == null
        ? 'Unknown'
        : WorkspaceTime.dateTime(parsed, scope.timezone);
  }

  @override
  Widget build(BuildContext context) => ManagerScopedDetails(
    cubit: cubit,
    scope: scope,
    child: AlertDialog(
      title: const Text('Immutable audit record'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${record.id}'),
            Text('Reason: ${record.text('reason')}'),
            Text(record.text('explanation')),
            Text('Created: ${_date('createdAt')}'),
            Text('Actor membership: ${record.text('createdByMembershipId')}'),
            Text('Policy version: ${record.text('policyVersionId')}'),
            if (record.reversed) ...[
              Text('Reversed: ${_date('reversedAt')}'),
              Text(record.text('reversalReason')),
              Text(record.text('reversalExplanation')),
            ],
            if (record.fields['ledgerEntries'] case final List entries)
              for (final entry in entries.whereType<Map>())
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    '${entry['pointType'] ?? 'Unknown'} ${entry['amount'] ?? 'Unknown'} · ${entry['reason'] ?? 'Unknown'}\nEntry: ${entry['id'] ?? 'Unknown'}',
                  ),
                ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Close'),
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
            child: const Text('Reverse record'),
          ),
      ],
    ),
  );
}
