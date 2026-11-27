import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/session/session_coordinator.dart';
import 'package:shiftly/core/theme/app_palette.dart';
import 'package:shiftly/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:shiftly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:shiftly/features/notifications/presentation/widgets/notification_bell.dart';

class EmployeeDashboardHeader extends StatelessWidget {
  const EmployeeDashboardHeader({
    required this.data,
    required this.state,
    super.key,
  });
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
      ],
    );
  }
}
