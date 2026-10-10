import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/extra_authorization.dart';
import 'package:shiftly/features/fixed_shifts/presentation/utils/saved_schedule_formatter.dart';

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
            context.tr('EXTRA · {value1} · Operational date {value2}', {
              'value1': context.tr(value.status),
              'value2': (value.operationalDate).toString(),
            }),
          ),
          Text(savedScheduleLabel(context, value.schedule)),
          Text(
            context.tr('{value1} · {value2}', {
              'value1': context.tr('${value.fields['reason']}'),
              'value2': (value.fields['explanation']).toString(),
            }),
          ),
          Text(
            context.tr('Authorization: {value1}', {
              'value1': (value.id).toString(),
            }),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            context.tr('Created by membership {value1}', {
              'value1': (value.fields['createdByMembershipId']).toString(),
            }),
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
                context.tr('{value1}: {value2}', {
                  'value1': context.tr(key),
                  'value2': (WorkspaceTime.dateTime(
                    DateTime.parse(value.fields[key] as String),
                    value.schedule.timezone,
                  )).toString(),
                }),
              ),
          if (value.fields['revokedByMembershipId'] != null)
            Text(
              context.tr('Revoked by membership {value1}', {
                'value1': (value.fields['revokedByMembershipId']).toString(),
              }),
            ),
          for (final record in value.attendance.whereType<Map>())
            Text(
              context.tr(
                'Attendance {value1} · {value2}\nEntered by membership {value3}',
                {
                  'value1': (record['id']).toString(),
                  'value2': (record['reviewStatus'] ?? 'Status unavailable')
                      .toString(),
                  'value3': (record['enteredByMembershipId'] ?? 'Not recorded')
                      .toString(),
                },
              ),
            ),
          if (!value.schedule.supported)
            Text(
              context.tr(
                'Unknown schedule conversion policy. Read-only evidence; contact support.',
              ),
            ),
          if (onRevoke != null && value.canRevoke)
            OutlinedButton.icon(
              onPressed: onRevoke,
              icon: const Icon(Icons.cancel_outlined),
              label: Text(context.tr('Revoke unused authorization')),
            ),
        ],
      ),
    ),
  );
}
