import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/presentation/widgets/assigned_team_task_tile.dart';

void main() {
  final task = AssignedTeamTask.fromJson({
    'id': 'task',
    'assigneeMembershipId': 'member',
    'title': 'Check inventory',
    'status': 'OPEN',
    'priority': 'HIGH',
    'createdAt': '2026-11-27T00:00:00Z',
  });

  Future<void> mount(
    WidgetTester tester, {
    required bool manager,
    required ValueChanged<String> onStatus,
    required VoidCallback onRemind,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AssignedTeamTaskTile(
          task: task,
          isManager: manager,
          busy: false,
          onStatus: onStatus,
          onRemind: onRemind,
        ),
      ),
    ),
  );

  testWidgets('manager can request a reminder without changing status', (
    tester,
  ) async {
    final statuses = <String>[];
    var reminders = 0;
    await mount(
      tester,
      manager: true,
      onStatus: statuses.add,
      onRemind: () => reminders++,
    );
    await tester.tap(find.text('Check inventory'));
    expect(find.byTooltip('Change task status'), findsNothing);
    await tester.tap(find.byTooltip('Remind employee'));
    expect(reminders, 1);
    expect(statuses, isEmpty);
  });

  testWidgets('employee status changes only after explicitly choosing one', (
    tester,
  ) async {
    final statuses = <String>[];
    await mount(
      tester,
      manager: false,
      onStatus: statuses.add,
      onRemind: () {},
    );
    await tester.tap(find.byTooltip('Change task status'));
    await tester.pumpAndSettle();
    expect(statuses, isEmpty);
    await tester.tap(
      find.widgetWithText(CheckedPopupMenuItem<String>, 'IN_PROGRESS'),
    );
    await tester.pumpAndSettle();
    expect(statuses, ['IN_PROGRESS']);
  });
}
