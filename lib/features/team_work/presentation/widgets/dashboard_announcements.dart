import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/widgets/pending_announcements.dart';

class DashboardAnnouncements extends StatelessWidget {
  const DashboardAnnouncements({super.key, required this.refreshToken});
  final Object refreshToken;

  @override
  Widget build(BuildContext context) {
    final scope = context.read<DashboardCubit>().scope;
    if (scope == null || !getIt.isRegistered<TeamWorkRepository>()) {
      return const SizedBox.shrink();
    }
    return PendingAnnouncements(
      key: ValueKey('${scope.workspaceId}:${scope.membershipId}'),
      repository: getIt<TeamWorkRepository>(),
      workspaceId: scope.workspaceId,
      timezone: scope.timezone,
      refreshToken: refreshToken,
    );
  }
}
