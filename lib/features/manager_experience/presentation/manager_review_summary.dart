import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/core/widgets/dashboard_card_loading.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';

class ManagerReviewSummary extends StatefulWidget {
  const ManagerReviewSummary({
    required this.workspaceId,
    this.refreshToken,
    super.key,
  });
  final String workspaceId;
  final Object? refreshToken;
  @override
  State<ManagerReviewSummary> createState() => _ManagerReviewSummaryState();
}

class _ManagerReviewSummaryState extends State<ManagerReviewSummary> {
  late Future<WorkPage<WorkTask>>? _future = _load();
  Future<WorkPage<WorkTask>>? _load() =>
      getIt.isRegistered<TeamWorkRepository>()
      ? getIt<TeamWorkRepository>().tasks(widget.workspaceId)
      : null;
  @override
  void didUpdateWidget(covariant ManagerReviewSummary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken ||
        oldWidget.workspaceId != widget.workspaceId) {
      _future = _load();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<WorkPage<WorkTask>>(
    future: _future,
    builder: (context, snapshot) {
      final tasks = snapshot.data?.items.where((t) => t.needsDecision).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.tr('Needs your review'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (tasks != null)
                Chip(
                  label: Text(
                    context.tr('{count} pending', {'count': '${tasks.length}'}),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData)
            const DashboardCardLoading(kind: DashboardCardKind.tile)
          else
            Card(
              child: ListTile(
                key: const Key('manager-action-inbox'),
                contentPadding: const EdgeInsets.all(16),
                leading: const Icon(Icons.assignment_outlined),
                title: Text(context.tr('Attendance & requests')),
                subtitle: Text(
                  tasks == null
                      ? context.tr('Attendance, leave and correction decisions')
                      : context.tr(
                          '{attendance} attendance · {leave} leave · {correction} correction',
                          {
                            'attendance':
                                '${tasks.where((t) => t.kind == 'ATTENDANCE').length}',
                            'leave':
                                '${tasks.where((t) => t.kind == 'LEAVE').length}',
                            'correction':
                                '${tasks.where((t) => t.kind == 'CORRECTION').length}',
                          },
                        ),
                ),
                onTap: () => context.push('/work?tab=tasks'),
              ),
            ),
          if (snapshot.hasError)
            TextButton(
              onPressed: () => setState(() => _future = _load()),
              child: Text(context.tr('Could not refresh reviews. Retry')),
            ),
        ],
      );
    },
  );
}
