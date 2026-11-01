import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shiftly/app.dart';
import 'package:shiftly/core/theme/app_theme.dart';
import 'package:shiftly/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:shiftly/features/employees/data/mock_employee_repository.dart';
import 'package:shiftly/features/team_work/domain/team_work_models.dart';
import 'package:shiftly/features/team_work/domain/team_work_repository.dart';
import 'package:shiftly/features/team_work/presentation/widgets/team_work_body.dart';

class SectionRepository implements TeamWorkRepository {
  final calls = <String>[];
  @override
  Future<WorkPage<WorkTask>> tasks(String w) async {
    calls.add('tasks');
    return const WorkPage([], 0);
  }

  @override
  Future<WorkPage<CorrectionRequest>> corrections(
    String w, {
    int page = 1,
    String? status,
  }) async {
    calls.add('corrections');
    return const WorkPage([], 0);
  }

  @override
  Future<WorkPage<TeamAnnouncement>> announcements(
    String w, {
    int page = 1,
    bool pendingOnly = false,
  }) async {
    calls.add('announcements');
    return const WorkPage([], 0);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final section in ['tasks', 'corrections', 'announcements']) {
    testWidgets('$section is a standalone screen and only loads its own feed', (
      tester,
    ) async {
      final repo = SectionRepository();
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme(),
          home: TeamWorkBody(
            workspaceId: 'workspace',
            timezone: 'Africa/Cairo',
            manager: true,
            initialTab: section,
            repository: repo,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(repo.calls, [section]);
      expect(find.byType(TabBar), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.byTooltip('Shift planning and handovers'), findsNothing);
      expect(find.byTooltip('Shift swaps and coverage'), findsNothing);
    });
  }
  testWidgets(
    'team and work destinations are named and preserve their deep links',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final employees = MockEmployeeRepository(delay: Duration.zero);
      await tester.pumpWidget(
        ShiftlyApp.preview(
          employeeRepository: employees,
          dashboardRepository: MockDashboardRepository(
            employeeRepository: employees,
            delay: Duration.zero,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Task manager'), findsNothing);
      expect(find.text('Quick actions'), findsNothing);
      expect(find.byKey(const Key('today-at-a-glance-card')), findsNothing);
      await tester.tap(find.byKey(const Key('nav-1')));
      await tester.pumpAndSettle();
      for (final name in [
        'employees',
        'invite',
        'attendance',
        'corrections',
        'reports',
      ]) {
        expect(find.byKey(Key('section-$name')), findsOneWidget);
      }
      await tester.tap(find.byKey(const Key('section-attendance')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('attendance-content')), findsOneWidget);
      expect(find.byKey(const Key('attendance-tab-requests')), findsNothing);
      await tester.tap(find.byKey(const Key('nav-2')));
      await tester.pumpAndSettle();
      for (final name in ['tasks', 'shifts', 'announcements', 'personal']) {
        expect(find.byKey(Key('section-$name')), findsOneWidget);
      }
      await tester.tap(find.byKey(const Key('section-shifts')));
      await tester.pumpAndSettle();
      final router = GoRouter.of(
        tester.element(find.byKey(const Key('manager-bottom-navigation'))),
      );
      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/work?tab=shifts',
      );
      expect(find.text('Fixed shift templates'), findsOneWidget);
      router.go('/attendance/reports');
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/employees?tab=reports',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
