import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:shiftly/features/attendance/presentation/cubit/manager_attendance_cubit.dart';
import 'package:shiftly/features/attendance/presentation/widgets/manager_attendance_filters_dialog.dart';
import 'package:shiftly/features/attendance/presentation/widgets/manager_attendance_lists.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';

class ManagerAttendancePanel extends StatelessWidget {
  const ManagerAttendancePanel({required this.timezone, super.key});
  final String timezone;

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<ManagerAttendanceCubit, ManagerAttendanceState>(
        listenWhen: (previous, current) =>
            previous.failure != current.failure && current.failure != null,
        listener: (context, state) =>
            ToastService.error(context, message: state.failure!.message),
        builder: (context, state) {
          if (state.initialLoading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 64),
              child: AppContentLoading(),
            );
          }
          if (state.records.isEmpty && state.pending.isEmpty) {
            return buildManagerAttendanceEmptyView(context, state);
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                key: const Key('attendance-date-employee-filters'),
                onPressed: () =>
                    showManagerAttendanceFilters(context, state, timezone),
                icon: const Icon(Icons.tune_rounded),
                label: Text(
                  state.query.from == null &&
                          state.query.employeeMembershipId == null
                      ? context.tr('Date and employee filters')
                      : context.tr('Change active filters'),
                ),
              ),
              const SizedBox(height: AppSpacing.s),
              _buildReviewDropdown(context, state),
              if (state.failure != null) ...[
                const SizedBox(height: AppSpacing.s),
                Text(
                  state.failure!.message,
                  style: TextStyle(color: AppPalette.of(context).error),
                ),
              ],
              ...buildManagerAttendanceListSections(context, state, timezone),
            ],
          );
        },
      );

  Widget _buildReviewDropdown(
    BuildContext context,
    ManagerAttendanceState state,
  ) => DropdownButtonFormField<AttendanceReviewStatus?>(
    key: const Key('attendance-review-filter'),
    initialValue: state.query.reviewStatus,
    decoration: InputDecoration(
      labelText: context.tr('Review status'),
      prefixIcon: const Icon(Icons.filter_list_rounded),
    ),
    items: [
      DropdownMenuItem(value: null, child: Text(context.tr('All records'))),
      for (final item in const [
        (AttendanceReviewStatus.pending, 'Pending'),
        (AttendanceReviewStatus.approved, 'Approved'),
        (AttendanceReviewStatus.rejected, 'Rejected'),
      ])
        DropdownMenuItem(value: item.$1, child: Text(context.tr(item.$2))),
    ],
    onChanged: (status) => context.read<ManagerAttendanceCubit>().load(
      query: AttendanceQuery(
        from: state.query.from,
        to: state.query.to,
        employeeMembershipId: state.query.employeeMembershipId,
        reviewStatus: status,
        shiftStatus: state.query.shiftStatus,
      ),
    ),
  );
}
