import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/offline/read_sync_banner.dart';
import 'package:shiftly/core/offline/read_sync_state.dart';
import 'package:shiftly/core/services/toast_service.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/widgets/app_content_loading.dart';
import 'package:shiftly/core/widgets/screen_header.dart';
import 'package:shiftly/features/shifts/domain/repositories/shift_repository.dart';
import 'package:shiftly/features/shifts/presentation/cubit/employee_shifts_cubit.dart';
import 'package:shiftly/features/shifts/presentation/widgets/employee_shifts_content.dart';

class EmployeeShiftsScreen extends StatelessWidget {
  const EmployeeShiftsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final timezone =
        context
            .watch<SessionCoordinator>()
            .state
            .activeMembership
            ?.workspace
            .timezone ??
        'Etc/UTC';
    return BlocConsumer<EmployeeShiftsCubit, EmployeeShiftsState>(
      listenWhen: (previous, current) =>
          previous.failure != current.failure && current.failure != null,
      listener: (context, state) =>
          ToastService.error(context, message: state.failure!.message),
      builder: (context, state) {
        if (state.initialLoading) return const AppContentLoading();
        if (state.records.isEmpty) {
          return buildEmptyEmployeeShifts(context, state);
        }
        final now = DateTime.now().toUtc();
        final upcoming = state.records
            .where(
              (i) => i.status == ShiftStatus.scheduled && i.endsAt.isAfter(now),
            )
            .toList(growable: false);
        final history = state.records
            .where((item) => !upcoming.contains(item))
            .toList(growable: false);
        Future<void> reload() =>
            context.read<EmployeeShiftsCubit>().load(refresh: true);
        return RefreshIndicator(
          onRefresh: reload,
          child: ListView(
            key: const Key('employee-shifts-list'),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            children: [
              ReadSyncBanner(
                category: ReadCategory.schedule,
                onRefresh: reload,
              ),
              ScreenHeader(
                title: context.tr('Legacy shifts'),
                subtitle: context.tr(
                  'Historical assigned schedules and active clock-out',
                ),
              ),
              if (state.failure != null)
                buildEmployeeShiftsFailureText(context, state.failure!.message),
              if (upcoming.isNotEmpty)
                ...buildEmployeeShiftSection(
                  context,
                  title: 'Legacy schedules',
                  shifts: upcoming,
                  timezone: timezone,
                ),
              if (history.isNotEmpty)
                ...buildEmployeeShiftSection(
                  context,
                  title: 'History',
                  shifts: history,
                  timezone: timezone,
                ),
              if (state.hasMore)
                OutlinedButton(
                  onPressed: state.loadingMore
                      ? null
                      : context.read<EmployeeShiftsCubit>().loadMore,
                  child: state.loadingMore
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.tr('Load more')),
                ),
            ],
          ),
        );
      },
    );
  }
}
