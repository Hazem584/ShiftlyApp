import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/utils/workspace_time.dart';
import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:shiftly/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:shiftly/features/profile/presentation/cubit/profile_cubit.dart';

class ManagerDashboardHeader extends StatelessWidget {
  const ManagerDashboardHeader({
    required this.data,
    required this.workspaceName,
    super.key,
  });
  final ManagerDashboardData data;
  final String? workspaceName;

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileCubit>().state;
    final name = profile is ProfileLoaded
        ? profile.profile.displayName.split(' ').first
        : context.tr('Manager');
    final time = WorkspaceTime.inWorkspace(data.generatedAt, data.timezone);
    final greeting = time.hour < 12
        ? 'Morning, {name}'
        : time.hour < 18
        ? 'Afternoon, {name}'
        : 'Evening, {name}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('WORKSPACE'),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    workspaceName?.isNotEmpty == true
                        ? workspaceName!
                        : context.tr('Workspace'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            const NotificationBell(),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          DateFormat(
            'EEEE, d MMMM',
            Localizations.localeOf(context).toString(),
          ).format(time),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(
          context.tr(greeting, {'name': name}),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }
}
