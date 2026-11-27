import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/employee_design.dart';
import 'package:shiftly/core/theme/manager_design.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/presentation/widgets/correction_request_card_helpers.dart';
import 'package:shiftly/features/team_work/presentation/widgets/correction_request_times_section.dart';

class CorrectionRequestCard extends StatelessWidget {
  const CorrectionRequestCard({
    super.key,
    required this.request,
    required this.timezone,
    this.onApprove,
    this.onDecline,
    this.busy = false,
    this.detailed = false,
  });
  final CorrectionRequest request;
  final String timezone;
  final VoidCallback? onApprove, onDecline;
  final bool busy, detailed;

  @override
  Widget build(BuildContext context) {
    if (EmployeeDesign.applies(context) &&
        !ManagerDesign.applies(context) &&
        !detailed) {
      return buildEmployeeCorrectionTile(context, request, timezone);
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(request.name, style: Theme.of(context).textTheme.titleMedium),
            if (request.isMissingAttendance) ...[
              Text(context.tr('Review missing attendance')),
              Text('${request.shiftName} · ${request.operationalDate}'),
              Text(context.tr(correctionReasonKindLabel(request.reasonKind))),
            ],
            Text(context.tr(correctionStatusLabel(request.status))),
            const SizedBox(height: 12),
            CorrectionRequestTimesSection(request: request, timezone: timezone),
            const Divider(),
            Text(request.reason),
            if (request.reviewNote != null) Text(request.reviewNote!),
            if (request.reviewer != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  context.tr('Reviewed by {name}', {'name': request.reviewer!}),
                ),
              ),
            if (request.reviewedAt != null)
              Text(
                formatCorrectionRequestTime(
                  context,
                  request.reviewedAt!,
                  timezone,
                ),
              ),
            if (request.status == 'PENDING' && onApprove != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: busy ? null : onApprove,
                      icon: const Icon(Icons.check),
                      label: Text(context.tr('Approve')),
                    ),
                    OutlinedButton.icon(
                      onPressed: busy ? null : onDecline,
                      icon: const Icon(Icons.close),
                      label: Text(context.tr('Decline')),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
