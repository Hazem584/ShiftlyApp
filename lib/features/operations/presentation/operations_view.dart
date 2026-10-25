import 'package:flutter/material.dart';
import 'package:shiftly/core/localization/app_localizations.dart';

import '../domain/operations_repository.dart';
import 'handovers_view.dart';
import 'planning_view.dart';
import 'profiles_view.dart';

class OperationsView extends StatelessWidget {
  const OperationsView({
    super.key,
    required this.repository,
    required this.workspaceId,
    required this.membershipId,
    required this.timezone,
    required this.manager,
    required this.isCurrent,
  });
  final OperationsRepository repository;
  final String workspaceId, membershipId, timezone;
  final bool manager;
  final bool Function() isCurrent;
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: manager ? 3 : 1,
    child: Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Shift planning and handovers')),
        bottom: TabBar(
          isScrollable: true,
          tabs: [
            if (manager) ...[
              Tab(text: context.tr('Weekly planning')),
              Tab(text: context.tr('Availability and skills')),
            ],
            Tab(text: context.tr('Shift handovers')),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          if (manager) ...[
            PlanningView(
              repository: repository,
              workspaceId: workspaceId,
              timezone: timezone,
              isCurrent: isCurrent,
            ),
            ProfilesView(
              repository: repository,
              workspaceId: workspaceId,
              timezone: timezone,
              isCurrent: isCurrent,
            ),
          ],
          HandoversView(
            repository: repository,
            workspaceId: workspaceId,
            membershipId: membershipId,
            timezone: timezone,
            manager: manager,
            isCurrent: isCurrent,
          ),
        ],
      ),
    ),
  );
}
