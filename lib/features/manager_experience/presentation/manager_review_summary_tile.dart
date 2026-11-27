import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/core/localization/app_localizations.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';

class ManagerReviewSummaryTile extends StatelessWidget {
  const ManagerReviewSummaryTile({required this.tasks, super.key});
  final List<WorkTask>? tasks;

  @override
  Widget build(BuildContext context) {
    int count(String kind) => tasks!.where((t) => t.kind == kind).length;
    return Card(
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
                    'attendance': '${count('ATTENDANCE')}',
                    'leave': '${count('LEAVE')}',
                    'correction': '${count('CORRECTION')}',
                  },
                ),
        ),
        onTap: () => context.push('/work?tab=tasks'),
      ),
    );
  }
}
