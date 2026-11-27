import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/core/widgets/failure_notice.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/active_attendance_card.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/attendance_status_card.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/day_exception_notices.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/flexible_attendance_actions.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/flexible_attendance_eligibility_card.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/flexible_attendance_open_cards.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/legacy_clock_in_review_card.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/saved_schedule_list.dart';

class FlexibleAttendancePanel extends StatelessWidget {
  const FlexibleAttendancePanel({required this.timezone, super.key});
  final String timezone;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<FlexibleAttendanceCubit, FlexibleAttendanceState>(
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.eligibility != null)
              DayExceptionNotices(notices: state.eligibility!.dayExceptions),
            if (!state.loading) ...[
              AttendanceStatusCard(state: state, timezone: timezone),
              const SizedBox(height: 12),
            ],
            if (state.failure != null) ...[
              FailureNotice(
                failure: state.failure!,
                refreshing: state.refreshing,
                onRefresh:
                    state.clockingOut || state.submittingTemplateId != null
                    ? null
                    : () => context.read<FlexibleAttendanceCubit>().load(
                        refresh: true,
                      ),
              ),
              const SizedBox(height: 12),
            ],
            _content(context, state),
          ],
        ),
      );

  Widget _content(BuildContext context, FlexibleAttendanceState state) {
    if (state.recovery == null &&
        state.templates.isNotEmpty &&
        state.eligibility == null &&
        (state.loading || state.failure != null)) {
      return SavedScheduleList(templates: state.templates);
    }
    if (state.loading) {
      return const SurfaceCard(
        child: SizedBox(height: 116, child: AppContentLoading()),
      );
    }
    if (state.recovery != null) {
      return buildFlexibleRecoveryCard(context, state);
    }
    final current = state.current;
    final legacyReview = LegacyClockInReviewCard(
      reviews: state.legacyReviews,
      onRefresh:
          state.refreshing ||
              state.clockingOut ||
              state.submittingTemplateId != null
          ? null
          : () => context.read<FlexibleAttendanceCubit>().load(refresh: true),
    );
    if (current != null && current.isOpen && current.isActionable) {
      final activeCard = ActiveAttendanceCard(
        attendance: current,
        timezone: timezone,
        busy: state.clockingOut,
        onClockOut: () => confirmFlexibleClockOut(context),
      );
      return state.legacyReviews.isEmpty
          ? activeCard
          : Column(
              children: [activeCard, const SizedBox(height: 10), legacyReview],
            );
    }
    if (current != null && current.isOpen) {
      return buildUnactionableOpenAttendanceCard(context, current);
    }
    if (state.legacyReviewRequired) return legacyReview;
    return buildFlexibleEligibilityCard(context, state, timezone, legacyReview);
  }
}
