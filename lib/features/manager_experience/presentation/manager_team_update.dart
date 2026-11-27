import 'package:flutter/material.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/dashboard_card_loading.dart';
import 'package:shiftly/features/manager_experience/presentation/manager_team_update_card.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';

class ManagerTeamUpdate extends StatefulWidget {
  const ManagerTeamUpdate({
    required this.workspaceId,
    this.refreshToken,
    super.key,
  });
  final String workspaceId;
  final Object? refreshToken;
  @override
  State<ManagerTeamUpdate> createState() => _ManagerTeamUpdateState();
}

class _ManagerTeamUpdateState extends State<ManagerTeamUpdate> {
  late Future<WorkPage<TeamAnnouncement>>? _future = _load();
  Future<WorkPage<TeamAnnouncement>>? _load() =>
      getIt.isRegistered<TeamWorkRepository>()
      ? getIt<TeamWorkRepository>().announcements(widget.workspaceId, page: 1)
      : null;

  @override
  void didUpdateWidget(covariant ManagerTeamUpdate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken ||
        oldWidget.workspaceId != widget.workspaceId) {
      _future = _load();
    }
  }

  @override
  Widget build(BuildContext context) =>
      FutureBuilder<WorkPage<TeamAnnouncement>>(
        future: _future,
        builder: (context, snapshot) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.tr('Team update'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData)
              const DashboardCardLoading(kind: DashboardCardKind.announcement)
            else
              ManagerTeamUpdateCard(item: snapshot.data?.items.firstOrNull),
          ],
        ),
      );
}
