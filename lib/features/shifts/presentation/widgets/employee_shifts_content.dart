import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/offline/read_sync_banner.dart';
import 'package:shiftly/core/offline/read_sync_state.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/core/widgets/screen_header.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';
import 'package:shiftly/features/shifts/presentation/cubit/employee_shifts_cubit.dart';
import 'package:shiftly/features/shifts/presentation/widgets/employee_shift_details_sheet.dart';
import 'package:shiftly/features/shifts/presentation/widgets/shift_card.dart';

Widget buildEmptyEmployeeShifts(
  BuildContext context,
  EmployeeShiftsState state,
) {
  Future<void> reload() =>
      context.read<EmployeeShiftsCubit>().load(refresh: true);
  return RefreshIndicator(
    onRefresh: reload,
    child: ListView(
      children: [
        ReadSyncBanner(category: ReadCategory.schedule, onRefresh: reload),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
          child: ScreenHeader(
            title: context.tr('Legacy shifts'),
            subtitle: context.tr('Historical assigned schedules'),
          ),
        ),
        SizedBox(
          height: 420,
          child: EmptyState(
            icon: state.failure == null
                ? Icons.event_available_outlined
                : Icons.cloud_off_outlined,
            title: state.failure == null
                ? 'No legacy shift history'
                : 'Could not load shifts',
            message:
                state.failure?.message ??
                'Use Fixed shifts for available templates and attendance.',
          ),
        ),
      ],
    ),
  );
}

List<Widget> buildEmployeeShiftSection(
  BuildContext context, {
  required String title,
  required List<ShiftRecord> shifts,
  required String timezone,
}) => [
  const SizedBox(height: AppSpacing.l),
  Text(context.tr(title), style: Theme.of(context).textTheme.titleLarge),
  const SizedBox(height: AppSpacing.s),
  for (final shift in shifts) ...[
    ShiftCard(
      key: Key('employee-shift-${shift.id}'),
      shift: shift,
      timezone: timezone,
      onTap: () => showEmployeeShiftDetailsSheet(context, shift.id, timezone),
    ),
    const SizedBox(height: 10),
  ],
];

Widget buildEmployeeShiftsFailureText(BuildContext context, String message) =>
    Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s),
      child: Text(
        message,
        style: TextStyle(color: AppPalette.of(context).error),
      ),
    );
