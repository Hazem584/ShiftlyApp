import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';

class ManagerTeamUpdate extends StatefulWidget {
  const ManagerTeamUpdate({required this.workspaceId, super.key});
  final String workspaceId;
  @override
  State<ManagerTeamUpdate> createState() => _ManagerTeamUpdateState();
}

class _ManagerTeamUpdateState extends State<ManagerTeamUpdate> {
  late final _future = getIt.isRegistered<TeamWorkRepository>()
      ? getIt<TeamWorkRepository>().announcements(widget.workspaceId, page: 1)
      : null;
  @override
  Widget build(BuildContext context) =>
      FutureBuilder<WorkPage<TeamAnnouncement>>(
        future: _future,
        builder: (context, snapshot) {
          final item = snapshot.data?.items.firstOrNull;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('Team update'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: InkWell(
                  onTap: () => context.go('/work?tab=announcements'),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item?.title ??
                              context.tr('Keep your team in the loop'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item?.body ??
                              context.tr(
                                'Publish updates and track acknowledgment',
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.tr(
                            item == null
                                ? 'Open announcements'
                                : 'View announcement →',
                          ),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
}
