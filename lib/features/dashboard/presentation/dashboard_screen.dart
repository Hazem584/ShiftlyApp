import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/constants/app_strings.dart';
import 'package:shiftly/core/models/attendance_record.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/core/widgets/empty_state.dart';
import 'package:shiftly/features/dashboard/data/dashboard_repository.dart';
import 'package:shiftly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:shiftly/features/dashboard/presentation/widgets/summary_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) => switch (state) {
            DashboardLoading() => const _DashboardLoading(),
            DashboardLoaded(:final data) => _DashboardContent(data: data),
            DashboardEmpty() => EmptyState(
              icon: Icons.people_outline,
              title: 'Your workplace is ready',
              message: 'Add your first employee to begin tracking shifts and attendance.',
              action: FilledButton.icon(
                onPressed: () => context.push('/employees/add'),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text(AppStrings.addEmployee),
              ),
            ),
            DashboardError(:final message) => EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Something went wrong',
              message: message,
              action: FilledButton.icon(
                onPressed: context.read<DashboardCubit>().load,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ),
          },
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: context.read<DashboardCubit>().load,
      child: ListView(
        key: const Key('dashboard-content'),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good morning, Manager',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      '${AppStrings.workplace} • ${_date(DateTime.now())}',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                child: const Text('M'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [
              SummaryCard(
                label: 'Total employees',
                value: data.totalEmployees,
                icon: Icons.groups_rounded,
                color: colors.primary,
              ),
              SummaryCard(
                label: 'Present today',
                value: data.presentEmployees,
                icon: Icons.check_circle_outline_rounded,
                color: const Color(0xFF15803D),
              ),
              SummaryCard(
                label: 'Absent',
                value: data.absentEmployees,
                icon: Icons.person_off_outlined,
                color: colors.error,
              ),
              SummaryCard(
                label: 'Late',
                value: data.lateEmployees,
                icon: Icons.schedule_rounded,
                color: const Color(0xFFB45309),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          _SectionTitle(
            title: 'Quick actions',
            trailing: '${data.pendingRequests} pending',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.person_add_alt_1_rounded,
                  label: AppStrings.addEmployee,
                  onTap: () => context.push('/employees/add'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.calendar_month_rounded,
                  label: AppStrings.createShift,
                  onTap: () => context.go('/attendance'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.approval_rounded,
                  label: AppStrings.reviewRequests,
                  onTap: () => context.go('/requests'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.l),
          const _SectionTitle(title: 'Current shift'),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.wb_sunny_outlined,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.currentShift.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          data.currentShift.timeRange,
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${data.currentShiftEmployees}\non shift',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.l),
          const _SectionTitle(title: 'Recent activity'),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                for (
                  var index = 0;
                  index < data.recentActivity.length;
                  index++
                ) ...[
                  _ActivityTile(record: data.recentActivity[index]),
                  if (index < data.recentActivity.length - 1)
                    const Divider(height: 1, indent: 64),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _date(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});
  final String title;
  final String? trailing;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      if (trailing != null) Chip(label: Text(trailing!)),
    ],
  );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Ink(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer
            .withValues(alpha: .55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 7),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.record});
  final AttendanceRecord record;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: CircleAvatar(child: Text(record.employeeName.substring(0, 1))),
    title: Text(record.employeeName),
    subtitle: Text(record.isLate ? 'Checked in late' : 'Checked in'),
    trailing: Text(
      _time(record.occurredAt),
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    ),
  );
  String _time(DateTime value) =>
      '${value.hour % 12 == 0 ? 12 : value.hour % 12}:${value.minute.toString().padLeft(2, '0')} ${value.hour >= 12 ? 'PM' : 'AM'}';
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();
  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Preparing your dashboard…'),
      ],
    ),
  );
}
