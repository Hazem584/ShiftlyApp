import 'package:flutter/material.dart';
import 'package:shiftly/core/utils/workspace_time.dart';

import '../../data/extra_authorization.dart';

class ExtraAuthorizationCard extends StatelessWidget {
  const ExtraAuthorizationCard({required this.value, this.onRevoke, super.key});
  final ExtraAuthorization value;
  final VoidCallback? onRevoke;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            value.schedule.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            'EXTRA · ${value.status} · Operational date ${value.operationalDate}',
          ),
          Text(value.schedule.summary),
          Text('${value.fields['reason']} · ${value.fields['explanation']}'),
          Text(
            'Authorization: ${value.id}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            'Created by membership ${value.fields['createdByMembershipId']}',
          ),
          for (final key in [
            'createdAt',
            'consumedAt',
            'revokedAt',
            'actualClockInAt',
            'actualClockOutAt',
          ])
            if (value.fields[key] is String)
              Text(
                '$key: ${WorkspaceTime.dateTime(DateTime.parse(value.fields[key] as String), value.schedule.timezone)}',
              ),
          if (value.fields['revokedByMembershipId'] != null)
            Text(
              'Revoked by membership ${value.fields['revokedByMembershipId']}',
            ),
          for (final record
              in (value.fields['attendance'] as List).whereType<Map>())
            Text(
              'Attendance ${record['id']} · ${record['reviewStatus'] ?? 'Status unavailable'}\nEntered by membership ${record['enteredByMembershipId'] ?? 'Not recorded'}',
            ),
          if (!value.schedule.supported)
            const Text(
              'Unknown schedule conversion policy. Read-only evidence; contact support.',
            ),
          if (onRevoke != null && value.canRevoke)
            OutlinedButton.icon(
              onPressed: onRevoke,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Revoke unused authorization'),
            ),
        ],
      ),
    ),
  );
}
