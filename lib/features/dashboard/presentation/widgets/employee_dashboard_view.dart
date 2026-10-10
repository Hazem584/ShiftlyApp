import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/core/widgets/surface_card.dart';
import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:shiftly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:shiftly/features/dashboard/presentation/utils/employee_dashboard_formatters.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/employee_dashboard_count_card.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/employee_dashboard_shift_card.dart';
import 'package:shiftly/features/fixed_shifts/presentation/cubit/fixed_shifts_cubit.dart';
import 'package:shiftly/features/fixed_shifts/presentation/widgets/attendance_status_card.dart';
import 'package:shiftly/features/points/presentation/widgets/performance_thumbnail.dart';

class EmployeeDashboardView extends StatelessWidget {
  const EmployeeDashboardView({
    super.key,
    required this.data,
    required this.state,
  });
  final EmployeeDashboardData data;
  final DashboardLoaded state;

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: () async {
      await Future.wait([
        context.read<DashboardCubit>().load(refresh: true),
        context.read<FlexibleAttendanceCubit>().load(refresh: true),
      ]);
    },
    child: ListView(
      key: const Key('employee-dashboard-content'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        Text(
          context.tr('Hello, {name}', {'name': data.employee.fullName}),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Text(
          context.tr('{value1} · {value2}', {
            'value1': (data.date).toString(),
            'value2': (data.timezone).toString(),
          }),
          style: TextStyle(color: AppPalette.of(context).textSecondary),
        ),
        if (state.failure != null) ...[
          const SizedBox(height: AppSpacing.s),
          Text(
            state.failure!.message,
            style: TextStyle(color: AppPalette.of(context).error, fontSize: 12),
          ),
        ],
        const SizedBox(height: AppSpacing.m),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppPalette.of(context).brandBackground,
                AppPalette.of(context).brandGradientEnd,
              ],
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
            ),
            borderRadius: BorderRadius.circular(AppRadii.xl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.wb_sunny_outlined,
                color: AppPalette.of(context).selected,
                size: 28,
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('Ready for your workday?'),
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr(
                  'Your shifts, attendance and time off are a tap away.',
                ),
                style: const TextStyle(color: Color(0xFFE4DED6), height: 1.5),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    key: const Key('employee-quick-shifts'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPalette.of(context).orange,
                    ),
                    onPressed: () => context.go('/employee?tab=shifts'),
                    icon: const Icon(Icons.fingerprint_rounded),
                    label: Text(context.tr('My Shifts')),
                  ),
                  OutlinedButton.icon(
                    key: const Key('employee-quick-leave'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF8E8E9C)),
                    ),
                    onPressed: () => context.go('/employee?tab=leave'),
                    icon: const Icon(Icons.event_note_outlined),
                    label: Text(context.tr('Request leave')),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        const PerformanceThumbnail(),
        const SizedBox(height: AppSpacing.m),
        BlocBuilder<FlexibleAttendanceCubit, FlexibleAttendanceState>(
          builder: (context, state) => AttendanceStatusCard(
            state: state,
            timezone: data.timezone,
            onOpenShifts: () => context.go('/employee?tab=shifts'),
          ),
        ),
        if (data.todayShift != null)
          EmployeeDashboardShiftCard(
            title: context.tr('Scheduled shift'),
            shift: data.todayShift,
            timezone: data.timezone,
            attendance: data.attendance,
          ),
        const SizedBox(height: AppSpacing.m),
        if (data.nextShift != null)
          EmployeeDashboardShiftCard(
            title: context.tr('Next scheduled shift'),
            shift: data.nextShift,
            timezone: data.timezone,
          ),
        const SizedBox(height: AppSpacing.m),
        Row(
          children: [
            Expanded(
              child: EmployeeDashboardCountCard(
                label: context.tr('Pending leave'),
                value: data.summary.pendingLeaveRequests,
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: EmployeeDashboardCountCard(
                label: context.tr('Upcoming approved'),
                value: data.summary.approvedLeaveRequests,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.l),
        Text(
          context.tr('Recent leave requests'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.s),
        SurfaceCard(
          padding: data.recentLeaveRequests.isEmpty
              ? const EdgeInsets.all(16)
              : EdgeInsets.zero,
          child: data.recentLeaveRequests.isEmpty
              ? Text(
                  context.tr('No leave requests yet.'),
                  style: TextStyle(color: AppPalette.of(context).textSecondary),
                )
              : Column(
                  children: [
                    for (final request in data.recentLeaveRequests)
                      ListTile(
                        key: Key('employee-dashboard-leave-${request.id}'),
                        title: Text(
                          employeeDashboardScreenLeaveType(request.type),
                        ),
                        subtitle: Text(
                          context.tr('{value1}\n{value2}', {
                            'value1': (WorkspaceTime.dateTime(
                              request.startsAt,
                              data.timezone,
                              locale: Localizations.localeOf(context)
                                  .toString(),
                            )).toString(),
                            'value2': (request.reason).toString(),
                          }),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          employeeDashboardScreenLeaveStatus(request.status),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    ),
  );
}
