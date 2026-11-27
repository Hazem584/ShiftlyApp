import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/fixed_shifts/domain/repositories/fixed_shift_repository.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/attendance_presentation.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_dialog.dart';

Future<void> confirmFlexibleClockIn(
  BuildContext context,
  EligibleShiftOccurrence entry,
  String timezone,
) async {
  final locale = Localizations.localeOf(context).toString();
  final eligibility = context.read<FlexibleAttendanceCubit>().state.eligibility;
  final needsSelfie = eligibility?.selfieMode == 'REQUIRED';
  final needsGeo = eligibility?.geofenceMode == 'ENFORCE';
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => ManagerDialog(
      title: Text(
        context.tr('Clock in to {value1}?', {'value1': entry.template.name}),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('{value1} – {value2}', {
              'value1': WorkspaceTime.time(
                entry.scheduledStartAt,
                timezone,
                locale: locale,
              ),
              'value2': WorkspaceTime.time(
                entry.scheduledEndAt,
                timezone,
                locale: locale,
              ),
            }),
          ),
          Text(
            context.tr('Operational date: {value1}', {
              'value1': entry.operationalDate,
            }),
          ),
          Text(
            context.tr('Classification: {value1}{value2}', {
              'value1': attendanceClassificationLabel(entry.classification),
              'value2': entry.lateMinutes > 0
                  ? ' • ${entry.lateMinutes} min late'
                  : '',
            }),
          ),
          if (needsGeo || needsSelfie) ...[
            const SizedBox(height: 8),
            Text(
              context.tr(
                needsGeo && needsSelfie
                    ? 'Location & front-camera selfie will be verified.'
                    : needsSelfie
                    ? 'A front-camera selfie will be captured.'
                    : 'Workplace GPS location will be verified.',
              ),
              style: Theme.of(dialogContext).textTheme.bodySmall,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(context.tr('Cancel')),
        ),
        FilledButton(
          key: const Key('confirm-flexible-clock-in'),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(context.tr('Clock in')),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final result = await context.read<FlexibleAttendanceCubit>().clockIn(entry);
  if (context.mounted && result == FixedShiftMutationResult.success) {
    ToastService.success(context, message: 'Clock-in confirmed.');
  }
}
