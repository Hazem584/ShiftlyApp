import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:shiftly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_active_attendance_screen.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_attendance_gate.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_attendance_hero.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_tasks_preview.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_tile.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:shiftly/features/team_work/presentation/widgets/dashboard_announcements.dart';

class EmployeeDashboardView extends StatelessWidget {
  const EmployeeDashboardView({
    super.key,
    required this.data,
    required this.state,
    this.now,
  });
  final DateTime Function()? now;
  final EmployeeDashboardData data;
  final DashboardLoaded state;
  @override
  Widget build(BuildContext context) {
    final colors = AppPalette.of(context);
    final workspace = context
        .watch<SessionCoordinator?>()
        ?.state
        .activeMembership
        ?.workspace;
    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          context.read<DashboardCubit>().load(refresh: true),
          context.read<FlexibleAttendanceCubit>().load(refresh: true),
        ]);
      },
      child: ListView(
        key: const Key('employee-dashboard-content'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  (workspace?.name ?? context.tr('Employee workspace'))
                      .toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ),
              const NotificationBell(),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            context.tr('Hello, {name}', {'name': data.employee.fullName}),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            DateFormat(
              'EEEE, d MMMM',
              Localizations.localeOf(context).toString(),
            ).format(DateTime.parse(data.date)),
            style: TextStyle(color: colors.textSecondary, fontSize: 15),
          ),
          if (state.failure != null) ...[
            const SizedBox(height: 12),
            Text(state.failure!.message, style: TextStyle(color: colors.error)),
          ],
          const SizedBox(height: 32),
          BlocBuilder<FlexibleAttendanceCubit, FlexibleAttendanceState>(
            builder: (context, attendance) {
              final active = attendance.current;
              return active != null &&
                      active.isOpen &&
                      active.isActionable &&
                      attendance.recovery == null &&
                      !attendance.recoveryBlocked
                  ? EmployeeAttendanceHero(
                      attendance: active,
                      now: now,
                      timezone: data.timezone,
                      overview: true,
                      onOpen: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => EmployeeActiveAttendanceScreen(
                            timezone: data.timezone,
                          ),
                        ),
                      ),
                    )
                  : EmployeeAttendanceGate(
                      state: attendance,
                      timezone: data.timezone,
                    );
            },
          ),
          const SizedBox(height: 24),
          EmployeeTasksPreview(timezone: data.timezone),
          const SizedBox(height: 14),
          DashboardAnnouncements(refreshToken: data),
          EmployeeTile(
            icon: Icons.campaign_outlined,
            title: context.tr('Team announcements'),
            subtitle: context.tr('Read the latest updates from your team'),
            onTap: () => context.push('/team-work?tab=announcements'),
          ),
          if (data.nextShift != null) ...[
            const SizedBox(height: 14),
            EmployeeTile(
              icon: Icons.calendar_today_outlined,
              title: context.tr('Next scheduled shift'),
              subtitle: WorkspaceTime.dateTime(
                data.nextShift!.startsAt,
                data.timezone,
                locale: Localizations.localeOf(context).toString(),
              ),
              onTap: () => context.go('/employee?tab=shifts'),
            ),
          ],
        ],
      ),
    );
  }
}
