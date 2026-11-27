import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_correction_details_screen.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_tile.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';

String formatCorrectionRequestTime(
  BuildContext context,
  DateTime value,
  String timezone,
) => WorkspaceTime.dateTime(
  value,
  timezone,
  locale: Localizations.localeOf(context).toString(),
);

String correctionStatusLabel(String status) => switch (status) {
  'PENDING' => 'Pending review',
  'APPROVED' => 'Approved',
  _ => 'Declined',
};

String correctionReasonKindLabel(String? kind) => switch (kind) {
  'FORGOT_TO_RECORD' => 'I attended but forgot to record attendance',
  'EXCEPTION' => 'I have an exception or special circumstance',
  _ => 'Other reason',
};

Widget buildEmployeeCorrectionTile(
  BuildContext context,
  CorrectionRequest request,
  String timezone,
) {
  String time(DateTime v) => formatCorrectionRequestTime(context, v, timezone);
  final dateLabel =
      request.operationalDate ??
      WorkspaceTime.dateKey(request.requestedIn, timezone);
  final shiftLabel = request.shiftName ?? context.tr('Request correction');
  final status = context.tr(correctionStatusLabel(request.status));
  return EmployeeTile(
    icon: Icons.edit_calendar_outlined,
    title: '$dateLabel · $shiftLabel',
    subtitle: '$status · ${time(request.requestedIn)} → ${time(request.requestedOut)}',
    onTap: () => Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => EmployeeCorrectionDetailsScreen(
          request: request,
          timezone: timezone,
        ),
      ),
    ),
  );
}
