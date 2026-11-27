import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:shiftly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/employee_dashboard_attendance_section.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/employee_dashboard_header.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_tasks_preview.dart';
import 'package:shiftly/features/employee_experience/presentation/employee_tile.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
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
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () => Future.wait([
      context.read<DashboardCubit>().load(refresh: true),
      context.read<FlexibleAttendanceCubit>().load(refresh: true),
    ]),
    child: ListView(
      key: const Key('employee-dashboard-content'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      children: [
        EmployeeDashboardHeader(data: data, state: state),
        const SizedBox(height: 32),
        EmployeeDashboardAttendanceSection(timezone: data.timezone, now: now),
        const SizedBox(height: 24),
        EmployeeTasksPreview(timezone: data.timezone),
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
            onTap: () => context.push('/employee?tab=shifts'),
          ),
        ],
        const SizedBox(height: 14),
        EmployeeTile(
          icon: Icons.campaign_outlined,
          title: context.tr('Team announcements'),
          subtitle: context.tr('Read the latest updates from your team'),
          onTap: () => context.push('/team-work?tab=announcements'),
        ),
        DashboardAnnouncements(refreshToken: data),
      ],
    ),
  );
}
