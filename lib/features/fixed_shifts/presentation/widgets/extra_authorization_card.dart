import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/fixed_shifts/domain/entities/extra_authorization.dart';
import 'package:shiftly/features/fixed_shifts/presentation/utils/saved_schedule_formatter.dart';

String extraShiftReasonLabel(BuildContext context, String raw) =>
    context.tr(switch (raw) {
      'COVERED_EMPLOYEE' => 'Covering a colleague',
      'ADDITIONAL_SHIFT' => 'Additional shift',
      'APPROVED_OVERTIME' => 'Approved overtime',
      'EMERGENCY_SUPPORT' => 'Emergency support',
      'HIGH_WORKLOAD_SUPPORT' => 'High workload support',
      _ => 'Other reason',
    });

(String, Color) _statusStyle(String status) => switch (status) {
  'AUTHORIZED' => ('Authorized', const Color(0xFF0284C7)),
  'CONSUMED' => ('Completed', const Color(0xFF16A34A)),
  'REVOKED' => ('Cancelled', const Color(0xFFDC2626)),
  _ => (status, const Color(0xFF64748B)),
};

class ExtraAuthorizationCard extends StatelessWidget {
  const ExtraAuthorizationCard({required this.value, this.onRevoke, super.key});
  final ExtraAuthorization value;
  final VoidCallback? onRevoke;

  String _fmtDate(String key) => WorkspaceTime.dateTime(
    DateTime.parse(value.fields[key] as String),
    value.schedule.timezone,
  );

  @override
  Widget build(BuildContext context) {
    final (statusText, statusColor) = _statusStyle(value.status);
    final createdBy =
        (value.fields['createdByName'] as String?) ?? context.tr('Manager');
    final revokedBy =
        (value.fields['revokedByName'] as String?) ?? context.tr('Manager');
    final reason = extraShiftReasonLabel(
      context,
      '${value.fields['reason'] ?? ''}',
    );
    final note = '${value.fields['explanation'] ?? ''}'.trim();
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${value.schedule.name} · ${value.operationalDate}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    context.tr(statusText),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              savedScheduleLabel(context, value.schedule),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(note.isEmpty ? reason : '$reason · $note'),
            const Divider(height: 18),
            if (value.fields['createdAt'] is String)
              Text(
                '${context.tr('Authorized by')}: $createdBy · ${_fmtDate('createdAt')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (value.fields['consumedAt'] is String)
              Text(
                '${context.tr('Completed at')}: ${_fmtDate('consumedAt')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (value.fields['revokedAt'] is String)
              Text(
                '${context.tr('Cancelled by')}: $revokedBy · ${_fmtDate('revokedAt')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (onRevoke != null && value.canRevoke) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onRevoke,
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: Text(context.tr('Cancel extra shift')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
