import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/team_work/domain/shift_exchange.dart';

class ExchangeRequestCard extends StatelessWidget {
  const ExchangeRequestCard({
    super.key,
    required this.request,
    required this.membershipId,
    required this.manager,
    required this.timezone,
    required this.busy,
    required this.onDecision,
  });
  final ShiftExchange request;
  final String membershipId, timezone;
  final bool manager, busy;
  final void Function(String) onDecision;
  @override
  Widget build(BuildContext context) {
    final a = request.requester, b = request.target;
    String name(Map<String, Object?> e) =>
        e['name'] as String? ?? context.tr('Employee');
    String shift(Map<String, Object?> e) =>
        (e['schedule'] as Map?)?['name'] as String? ?? '';
    String period(Map<String, Object?> e) =>
        '${WorkspaceTime.dateTime(DateTime.parse(e['scheduledStartAt']! as String), (e['schedule'] as Map)['timezone'] as String, locale: Localizations.localeOf(context).toString())} - ${WorkspaceTime.dateTime(DateTime.parse(e['scheduledEndAt']! as String), (e['schedule'] as Map)['timezone'] as String, locale: Localizations.localeOf(context).toString())}';
    final status = request.expired ? 'EXPIRED' : request.status;
    final label = switch (status) {
      'PENDING_PEER' => 'Waiting for colleague',
      'PENDING_MANAGER' => 'Waiting for manager approval',
      'APPROVED' => 'Approved',
      'DECLINED' => 'Declined by colleague',
      'REJECTED' => 'Declined by manager',
      'CANCELLED' => 'Cancelled',
      'EXPIRED' => 'Request expired',
      _ => 'Unknown',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr(
                request.kind == 'COVER'
                    ? 'Coverage request'
                    : 'Shift swap request',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(context.tr(label)),
            Text(request.reason),
            const SizedBox(height: 8),
            Text('${name(a)} · ${request.requesterDate} · ${shift(a)}'),
            Text(period(a)),
            Text(
              '${name(b)} · ${request.targetDate} · ${b['expected'] == true ? shift(b) : context.tr('Day off')}',
            ),
            if (b['expected'] == true) Text(period(b)),
            const SizedBox(height: 8),
            Text(
              context.tr('After approval: {employee} works {shift}', {
                'employee': name(b),
                'shift': shift(a),
              }),
            ),
            Text(
              request.kind == 'COVER'
                  ? context.tr('After approval: {employee} has a day off', {
                      'employee': name(a),
                    })
                  : context.tr('After approval: {employee} works {shift}', {
                      'employee': name(a),
                      'shift': shift(b),
                    }),
            ),
            if (request.pending && !request.expired)
              Text(
                context.tr('Respond before {date}', {
                  'date': WorkspaceTime.dateTime(
                    request.expiresAt,
                    timezone,
                    locale: Localizations.localeOf(context).toString(),
                  ),
                }),
              ),
            if (request.peerNote != null) Text(request.peerNote!),
            if (request.reviewNote != null) Text(request.reviewNote!),
            if (request.reviewer != null)
              Text(
                context.tr('Reviewed by {name}', {'name': request.reviewer!}),
              ),
            Wrap(
              spacing: 8,
              children: [
                if (!manager &&
                    membershipId == request.targetId &&
                    status == 'PENDING_PEER') ...[
                  FilledButton(
                    onPressed: busy ? null : () => onDecision('ACCEPT'),
                    child: Text(context.tr('Accept request')),
                  ),
                  OutlinedButton(
                    onPressed: busy ? null : () => onDecision('DECLINE'),
                    child: Text(context.tr('Decline')),
                  ),
                ],
                if (manager && status == 'PENDING_MANAGER') ...[
                  FilledButton(
                    onPressed: busy ? null : () => onDecision('APPROVE'),
                    child: Text(context.tr('Approve schedule change')),
                  ),
                  OutlinedButton(
                    onPressed: busy ? null : () => onDecision('REJECT'),
                    child: Text(context.tr('Decline')),
                  ),
                ],
                if (!manager &&
                    membershipId == request.requesterId &&
                    request.pending)
                  TextButton(
                    onPressed: busy ? null : () => onDecision('CANCEL'),
                    child: Text(context.tr('Cancel request')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
