import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/di/service_locator.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';

class ManagerReviewSummary extends StatefulWidget {
  const ManagerReviewSummary({required this.workspaceId, super.key});
  final String workspaceId;
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
              onTap: () => context.go('/work?tab=tasks'),
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
